import os, re, time, requests, json
from bs4 import BeautifulSoup
from google.cloud import firestore
from fastapi import FastAPI, Response

FACULTY_LIST_URL = os.environ.get("SLU_FACULTY_LIST_URL", "")
# New SLU courses API URL
COURSES_API_URL = "https://courses.slu.edu/api/?page=fose&route=search"
COURSES_BASE_URL = "https://courses.slu.edu/"

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

def scrape_courses_from_api():
  """Scrape courses and class sessions from the new courses.slu.edu API"""
  print(f"[COURSES] Scraping courses from {COURSES_API_URL}")
  
  try:
    headers = {
      'Content-Type': 'application/json',
      'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
      'Referer': COURSES_BASE_URL
    }
    
    # Get all courses - empty search returns all results
    search_payload = {
      "other": {"srcdb": ""},
      "criteria": []
    }
    
    print("[COURSES] Making API request to get course data...")
    
    # Make the API request
    response = requests.post(COURSES_API_URL, json=search_payload, headers=headers, timeout=60)
    
    if response.status_code != 200:
      print(f"[COURSES] API request failed with status {response.status_code}")
      print(f"[COURSES] Response: {response.text}")
      return []
    
    data = response.json()
    print(f"[COURSES] API response received, parsing...")
    
    courses_with_sessions = []
    
    # Parse the API response to extract course and session information
    if 'results' in data:
      results = data['results']
      print(f"[COURSES] Found {len(results)} course sessions")
      
      for course_entry in results:
        # Extract basic course information
        course_code = course_entry.get('code', '')
        course_title = course_entry.get('title', '')
        
        # Extract department from course code (e.g., ACCT from ACCT 1220)
        dept_match = re.match(r'^([A-Z]+)', course_code)
        dept = dept_match.group(1) if dept_match else 'UNKNOWN'
        
        # Extract instructor information from the 'instr' field
        instructor_names = []
        if course_entry.get('instr'):
          # Handle multiple instructors separated by '/' 
          raw_instructors = course_entry['instr'].split('/')
          for instr in raw_instructors:
            instr = instr.strip()
            if instr and instr not in ['Staff', 'TBA']:
              instructor_names.append(instr)
        
        # Process this course session
        for instructor_name in instructor_names if instructor_names else ['Staff']:
          session_info = {
            'course_code': course_code,
            'course_title': course_title,
            'department': dept,
            'school': 'SLU',
            'section_number': course_entry.get('section', course_entry.get('no', '')),
            'crn': course_entry.get('crn', ''),
            'instructor_name': instructor_name,
            'instructor_email': '',  # We'll try to match this with faculty data
            'meeting_times': course_entry.get('meetingTimes', '[]'),
            'credits': '',  # Not directly available in this format
            'capacity': course_entry.get('total', ''),
            'enrolled': '',  # Not directly available
            'waitlist': '',  # Not directly available
            'term': '',  # We could extract this from term selection
            'status': course_entry.get('stat', 'A'),
            'start_date': course_entry.get('start_date', ''),
            'end_date': course_entry.get('end_date', ''),
            'schedule_type': course_entry.get('schd', ''),
            'campus': course_entry.get('campus_code', '')
          }
          
          # Try to extract instructor email if instructor name is available
          if instructor_name and instructor_name not in ['Staff', 'TBA']:
            # Clean up instructor name and generate potential email
            clean_name = re.sub(r'\s*\([^)]*\)', '', instructor_name).strip()
            name_parts = clean_name.split()
            
            if len(name_parts) >= 2:
              first = name_parts[0].lower()
              last = name_parts[-1].lower()
              # Remove any title prefixes and handle initials
              first = re.sub(r'^(dr|prof|professor)\.?', '', first)
              first = re.sub(r'\.', '', first)  # Remove dots from initials like "A."
              last = re.sub(r'\.', '', last)
              if first and last:  # Make sure both parts exist after cleaning
                session_info['instructor_email'] = f"{first}.{last}@slu.edu"
          
          courses_with_sessions.append(session_info)
    
    print(f"[COURSES] Extracted {len(courses_with_sessions)} course sessions")
    return courses_with_sessions
    
  except Exception as e:
    print(f"[COURSES] Error scraping from API: {str(e)}")
    # Fallback to a broader search
    try:
      print("[COURSES] Trying fallback search...")
      
      # Try a broader search without specific term
      fallback_payload = {
        "other": {"srcdb": ""},
        "criteria": []
      }
      
      response = requests.post(COURSES_API_URL, json=fallback_payload, headers=headers, timeout=60)
      
      if response.status_code == 200:
        data = response.json()
        print(f"[COURSES] Fallback search returned data, processing...")
        # Process similar to above
        return []  # For now, return empty on fallback
      else:
        print(f"[COURSES] Fallback search also failed: {response.status_code}")
        
    except Exception as fallback_error:
      print(f"[COURSES] Fallback search error: {str(fallback_error)}")
    
    return []


def scrape_courses_catalog():
  """Updated function to use the new API-based scraper"""
  return scrape_courses_from_api()


def _infer_dept_from_url(url: str) -> str:
  m = re.search(r"/courses-az/([^/]+)/?", url)
  return (m.group(1).upper() if m else "UNKNOWN")

# Remove the old scraping function and replace with a placeholder
def scrape_courses_catalog_old():
  """Legacy course catalog scraper - kept for reference"""
  print(f"[COURSES] Legacy catalog scraping is deprecated, use scrape_courses_from_api instead")
  return []

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
    print("[COURSES] Starting course catalog scraping from courses.slu.edu API...")
    
    data = scrape_courses_catalog()
    print(f"[COURSES] Scraped {len(data)} course sessions, writing to Firestore...")
    
    if not data:
      print("[COURSES] No course data retrieved")
      return {"ok": False, "message": "No course data retrieved", "count": 0}
    
    # Write course sessions to Firestore
    batch = db.batch()
    coll = db.collection("course_sessions")
    
    # Also maintain a courses catalog for unique courses
    courses_coll = db.collection("courses_catalog")
    unique_courses = {}
    
    written = 0
    def flush_batch(b):
      nonlocal written
      b.commit()
      written += 1
    
    i = 0
    b = db.batch()
    
    for session in data:
      # Create document ID for the session
      session_id = f"{session['course_code'].replace(' ', '_')}_{session['section_number']}_{session.get('crn', 'unknown')}"
      session_id = re.sub(r'[^a-zA-Z0-9_\-]', '_', session_id)[:500]
      
      # Write session data
      session_ref = coll.document(session_id)
      b.set(session_ref, {
        **session,
        "source": "courses_api",
        "updatedAt": firestore.SERVER_TIMESTAMP,
      }, merge=True)
      
      # Track unique courses
      course_key = f"{session['course_code']}|{session['course_title']}"
      if course_key not in unique_courses:
        unique_courses[course_key] = {
          "code": session['course_code'],
          "title": session['course_title'],
          "dept": session['department'],
          "school": session['school'],
        }
      
      i += 1
      if i % 400 == 0:
        flush_batch(b)
        b = db.batch()
    
    # Write remaining sessions
    if i % 400 != 0:
      flush_batch(b)
    
    # Write unique courses to courses_catalog
    print(f"[COURSES] Writing {len(unique_courses)} unique courses to catalog...")
    b = db.batch()
    
    for course_data in unique_courses.values():
      course_id = re.sub(r'[^a-zA-Z0-9_\-]', '_', f"{course_data['code'].replace(' ', '_')}__{course_data['title']}")[:500]
      course_ref = courses_coll.document(course_id)
      b.set(course_ref, {
        **course_data,
        "source": "courses_api",
        "updatedAt": firestore.SERVER_TIMESTAMP,
      }, merge=True)
    
    flush_batch(b)
    
    print(f"[COURSES] Completed! Wrote {len(data)} sessions and {len(unique_courses)} courses.")
    return {
      "ok": True, 
      "sessions_count": len(data), 
      "courses_count": len(unique_courses),
      "batches": written + 1
    }
    
  except Exception as e:
    print(f"[COURSES] Error: {str(e)}")
    return Response(str(e), status_code=500)

def link_teachers_with_courses():
  """Link teachers from faculty directory with their course sessions"""
  print("[LINK] Starting teacher-course linking process...")
  
  try:
    # Get all course sessions from Firestore
    sessions_ref = db.collection("course_sessions")
    sessions = sessions_ref.get()
    
    # Get all teachers from Firestore
    teachers_ref = db.collection("teachers_dir")
    teachers = teachers_ref.get()
    
    # Create email to teacher mapping
    teacher_by_email = {}
    for teacher_doc in teachers:
      if teacher_doc.exists:
        teacher_data = teacher_doc.to_dict()
        email = teacher_data.get('email', '').lower()
        if email:
          teacher_by_email[email] = {
            'doc_id': teacher_doc.id,
            'data': teacher_data,
            'teaching_sessions': []
          }
    
    print(f"[LINK] Found {len(teacher_by_email)} teachers in directory")
    
    # Process course sessions and match with teachers
    session_count = 0
    matched_count = 0
    
    for session_doc in sessions:
      if session_doc.exists:
        session_data = session_doc.to_dict()
        instructor_email = session_data.get('instructor_email', '').lower()
      
      if instructor_email and instructor_email in teacher_by_email:
        # Add this session to the teacher's teaching list
        session_info = {
          'course_code': session_data.get('course_code', ''),
          'course_title': session_data.get('course_title', ''),
          'section_number': session_data.get('section_number', ''),
          'crn': session_data.get('crn', ''),
          'term': session_data.get('term', ''),
          'meeting_times': session_data.get('meeting_times', []),
          'credits': session_data.get('credits', ''),
          'capacity': session_data.get('capacity', 0),
          'enrolled': session_data.get('enrolled', 0),
          'session_id': session_doc.id
        }
        
        teacher_by_email[instructor_email]['teaching_sessions'].append(session_info)
        matched_count += 1
      
      session_count += 1
    
    print(f"[LINK] Processed {session_count} sessions, matched {matched_count} to teachers")
    
    # Update teacher documents with their teaching sessions
    batch = db.batch()
    updated_teachers = 0
    
    for email, teacher_info in teacher_by_email.items():
      if teacher_info['teaching_sessions']:
        teacher_ref = teachers_ref.document(teacher_info['doc_id'])
        
        # Update teacher document with teaching sessions
        batch.update(teacher_ref, {
          'teachingSessions': teacher_info['teaching_sessions'],
          'totalSessions': len(teacher_info['teaching_sessions']),
          'updatedAt': firestore.SERVER_TIMESTAMP,
        })
        
        updated_teachers += 1
        
        print(f"[LINK] {teacher_info['data'].get('fullName', email)}: {len(teacher_info['teaching_sessions'])} sessions")
    
    # Commit the batch update
    batch.commit()
    
    print(f"[LINK] Updated {updated_teachers} teacher records with course sessions")
    return {
      'teachers_updated': updated_teachers,
      'sessions_processed': session_count,
      'matches_found': matched_count
    }
    
  except Exception as e:
    print(f"[LINK] Error linking teachers with courses: {str(e)}")
    raise


@app.get("/healthz")
def healthz():
  return {"ok": True}


@app.get("/seed_all")
def seed_all():
  """Complete scraping and linking process"""
  try:
    print("[SEED_ALL] Starting complete teacher and course synchronization...")
    
    # Step 1: Update teacher directory
    print("[SEED_ALL] Step 1: Updating teacher directory...")
    teacher_result = seed()
    if not isinstance(teacher_result, dict) or not teacher_result.get('ok'):
      return Response("Failed to update teacher directory", status_code=500)
    
    # Step 2: Scrape course sessions
    print("[SEED_ALL] Step 2: Scraping course sessions...")
    courses_result = seed_courses()
    if not isinstance(courses_result, dict) or not courses_result.get('ok'):
      return Response("Failed to scrape courses", status_code=500)
    
    # Step 3: Link teachers with courses
    print("[SEED_ALL] Step 3: Linking teachers with course sessions...")
    link_result = link_teachers_courses()
    if not isinstance(link_result, dict) or not link_result.get('ok'):
      return Response("Failed to link teachers with courses", status_code=500)
    
    final_result = {
      "ok": True,
      "teacher_updates": teacher_result.get('updated', 0),
      "course_sessions": courses_result.get('sessions_count', 0),
      "unique_courses": courses_result.get('courses_count', 0),
      "teachers_linked": link_result.get('teachers_updated', 0),
      "sessions_matched": link_result.get('matches_found', 0),
      "message": "Complete synchronization successful"
    }
    
    print(f"[SEED_ALL] Complete! {final_result}")
    return final_result
    
  except Exception as e:
    print(f"[SEED_ALL] Error: {str(e)}")
    return Response(str(e), status_code=500)

@app.get("/link_teachers_courses")
def link_teachers_courses():
  """API endpoint to link teachers with their course sessions"""
  try:
    result = link_teachers_with_courses()
    return {"ok": True, **result}
  except Exception as e:
    print(f"[LINK] Error: {str(e)}")
    return Response(str(e), status_code=500)
