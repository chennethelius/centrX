import os, re, time, requests
from bs4 import BeautifulSoup
from google.cloud import firestore
from fastapi import FastAPI, Response

FACULTY_LIST_URL = os.environ.get("SLU_FACULTY_LIST_URL", "")
# Comma-separated list of catalog URLs, e.g. https://catalog.slu.edu/courses-az/acct/,https://catalog.slu.edu/courses-az/fin/
COURSE_CATALOG_URLS = [u.strip() for u in os.environ.get("COURSE_CATALOG_URLS", "").split(",") if u.strip()]

app = FastAPI()
db = firestore.Client()  # uses Cloud Run service account

def _sanitize_id(email: str) -> str:
  return re.sub(r'[@.]', '_', email.lower())

def scrape_faculty():
  if not FACULTY_LIST_URL:
    raise RuntimeError("Missing SLU_FACULTY_LIST_URL")
  
  print(f"[SCRAPER] Fetching faculty directory from {FACULTY_LIST_URL}")
  html = requests.get(FACULTY_LIST_URL, timeout=30).text
  soup = BeautifulSoup(html, "html.parser")
  
  # Find accordion sections and faculty within each department
  people = {}
  
  # Look for accordion toggles that contain department names
  accordion_toggles = soup.find_all('a', class_='accordion__toggle')
  
  print(f"[SCRAPER] Found {len(accordion_toggles)} accordion sections")
  
  for toggle in accordion_toggles:
    # Extract department name from the accordion toggle text
    dept_span = toggle.find('span', class_='accordion__toggle__text')
    if not dept_span:
      continue
    
    dept_name = dept_span.get_text(strip=True)
    print(f"[SCRAPER] Processing department: {dept_name}")
    
    # Find the accordion content section that follows this toggle
    # Look for the parent accordion item and then find the content section
    accordion_item = toggle.find_parent('div')
    if not accordion_item:
      continue
    
    # Find faculty links in the accordion content section
    faculty_links = accordion_item.find_all('a', href=re.compile(r'/business/about/faculty/.*\.php$'))
    faculty_count = 0
    
    for a in faculty_links:
      href = a.get("href", "")
      if href and "directory.php" not in href:
        full_name = a.get_text(strip=True)
        
        # Clean up the name and generate email
        clean_name = full_name.replace(",", "").replace("Ph.D.", "").replace("J.D.", "").replace("Dr.", "").replace("M.A.", "").replace("M.B.A.", "").replace("M.Sc.", "").strip()
        name_parts = clean_name.split()
        
        if len(name_parts) >= 2:
          first = name_parts[0].lower()
          last = name_parts[-1].lower()
          email = f"{first}.{last}@slu.edu"
          
          if email not in people:
            people[email] = {"fullName": full_name, "department": dept_name}
            faculty_count += 1
            print(f"[SCRAPER] {full_name} -> {email} ({dept_name})")
    
    print(f"[SCRAPER] Found {faculty_count} faculty in {dept_name}")
  
  # Fallback: if accordion parsing didn't work, use generic approach
  if not people:
    print("[SCRAPER] Accordion parsing failed, falling back to generic approach...")
    faculty_links = soup.select('a[href*="/business/about/faculty/"][href$=".php"]')
    
    for a in faculty_links:
      href = a.get("href", "")
      if href and "directory.php" not in href:
        full_name = a.get_text(strip=True)
        
        # Clean up the name and generate email
        clean_name = full_name.replace(",", "").replace("Ph.D.", "").replace("J.D.", "").replace("Dr.", "").replace("M.A.", "").replace("M.B.A.", "").replace("M.Sc.", "").strip()
        name_parts = clean_name.split()
        
        if len(name_parts) >= 2:
          first = name_parts[0].lower()
          last = name_parts[-1].lower()
          email = f"{first}.{last}@slu.edu"
          
          if email not in people:
            people[email] = {"fullName": full_name, "department": "SLU Business"}
            print(f"[SCRAPER] {full_name} -> {email} (SLU Business)")
  
  print(f"[SCRAPER] Final count: {len(people)} faculty with emails")
  return [{"email": e, "fullName": data["fullName"], "department": data["department"]} for e, data in people.items()]

def _infer_dept_from_url(url: str) -> str:
  m = re.search(r"/courses-az/([^/]+)/?", url)
  return (m.group(1).upper() if m else "UNKNOWN")

def scrape_courses_catalog():
  print(f"[COURSES] Scraping {len(COURSE_CATALOG_URLS)} catalog URLs...")
  courses = []
  for url in COURSE_CATALOG_URLS:
    try:
      print(f"[COURSES] Processing {url}")
      resp = requests.get(url, timeout=30)
      if resp.status_code != 200:
        print(f"[COURSES] Failed to fetch {url}: {resp.status_code}")
        continue
      dept = _infer_dept_from_url(url)
      print(f"[COURSES] Department: {dept}")
      soup = BeautifulSoup(resp.text, "html.parser")
      # Heuristics: look for common catalog structures first
      title_nodes = soup.select('.courseblocktitle, .course-title, p, li, h3, h4, strong')
      seen = set()
      page_courses = 0
      for node in title_nodes:
        text = node.get_text(" ", strip=True)
        for line in text.splitlines():
          line = line.strip()
          m = re.match(r'^([A-Z]{2,5})\s*(\d{3,4}[A-Z]?)\s*[-–:]\s*(.+)$', line)
          if not m:
            continue
          prefix, number, name = m.group(1), m.group(2), m.group(3)
          code = f"{prefix} {number}".strip()
          key = f"{code}|{name}"
          if key in seen:
            continue
          seen.add(key)
          courses.append({
            "code": code,
            "title": name,
            "dept": dept,
            "school": "SLU Business",
          })
          page_courses += 1
      print(f"[COURSES] Found {page_courses} courses from {url}")
    except Exception as e:
      print(f"[COURSES] Error processing {url}: {str(e)}")
      continue
  # Deduplicate across pages
  uniq = {}
  for c in courses:
    key = f"{c['code']}|{c['title']}"
    if key not in uniq:
      uniq[key] = c
  print(f"[COURSES] Total unique courses: {len(uniq)}")
  return list(uniq.values())

def upsert_teachers_dir():
  print("[SEED] Starting teacher directory update...")
  faculty = scrape_faculty()
  count = 0
  for f in faculty:
    email = f["email"].lower()
    full_name = f.get("fullName") or email
    department = f.get("department", "SLU Business")
    doc_id = _sanitize_id(email)
    print(f"[SEED] Writing {full_name} ({email}) - {department} to Firestore...")
    db.collection("teachers_dir").document(doc_id).set({
      "email": email,
      "fullName": full_name,
      "department": department,
      "school": "SLU Business",
      # Courses are managed via a global catalog; teachers can select from it in-app.
      "courses": [],
      "source": "scrape",
      "updatedAt": firestore.SERVER_TIMESTAMP,
    }, merge=True)
    count += 1
    time.sleep(0.2)  # be gentle
  print(f"[SEED] Completed! Updated {count} teacher records.")
  return count

@app.get("/seed")
def seed():
  try:
    print("[SEED] Starting teacher directory seeding...")
    n = upsert_teachers_dir()
    print(f"[SEED] Successfully completed with {n} updates.")
    return {"ok": True, "updated": n}
  except Exception as e:
    print(f"[SEED] Error: {str(e)}")
    return Response(str(e), status_code=500)

@app.get("/seed_courses")
def seed_courses():
  try:
    print("[COURSES] Starting course catalog scraping...")
    if not COURSE_CATALOG_URLS:
      return Response("Missing COURSE_CATALOG_URLS", status_code=400)
    data = scrape_courses_catalog()
    print(f"[COURSES] Scraped {len(data)} courses, writing to Firestore...")
    batch = db.batch()
    coll = db.collection("courses_catalog")
    # Write in batches of 400 (Firestore batch limit is 500)
    written = 0
    def flush_batch(b):
      nonlocal written
      b.commit()
      written += 1
    i = 0
    b = db.batch()
    for item in data:
      # doc id like ACCT_1220__Title
      doc_id = re.sub(r'[^a-zA-Z0-9_\-]', '_', f"{item['code'].replace(' ', '_')}__{item['title']}")[:500]
      ref = coll.document(doc_id)
      b.set(ref, {
        **item,
        "source": "catalog",
        "updatedAt": firestore.SERVER_TIMESTAMP,
      }, merge=True)
      i += 1
      if i % 400 == 0:
        flush_batch(b)
        b = db.batch()
    if i % 400 != 0:
      flush_batch(b)
    print(f"[COURSES] Completed! Wrote {len(data)} courses in {written} batches.")
    return {"ok": True, "count": len(data), "batches": written}
  except Exception as e:
    print(f"[COURSES] Error: {str(e)}")
    return Response(str(e), status_code=500)

@app.get("/healthz")
def healthz():
  return {"ok": True}

@app.get("/debug")
def debug_accordion_structure():
  """Debug endpoint to examine accordion structure"""
  try:
    print(f"[DEBUG] Fetching faculty directory from {FACULTY_LIST_URL}")
    html = requests.get(FACULTY_LIST_URL, timeout=30).text
    soup = BeautifulSoup(html, "html.parser")
    
    results = {"accordions": [], "faculty_sample": []}
    
    # Look for accordion toggles
    accordion_toggles = soup.find_all('a', class_='accordion__toggle')
    for toggle in accordion_toggles:
      dept_span = toggle.find('span', class_='accordion__toggle__text')
      if dept_span:
        dept_name = dept_span.get_text(strip=True)
        results["accordions"].append(dept_name)
    
    # Sample faculty links
    faculty_links = soup.select('a[href*="/business/about/faculty/"][href$=".php"]')
    for a in faculty_links[:10]:
      results["faculty_sample"].append(f"{a.get_text(strip=True)} -> {a.get('href')}")
    
    return results
    
  except Exception as e:
    return {"error": str(e)}
