#!/usr/bin/env python3
"""
Test script focused on business school courses
"""

import requests
import json
from collections import defaultdict

COURSES_API_URL = "https://courses.slu.edu/api/?page=fose&route=search"

def test_business_courses():
    """Test scraping specifically for business school courses"""
    
    headers = {
        'Content-Type': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
        'Referer': 'https://courses.slu.edu/'
    }
    
    # Test with business-related keywords
    business_keywords = ['ACCT', 'MGMT', 'FINC', 'MKTG', 'ECON', 'ENTP', 'SCMO', 'IBSS']
    
    all_business_courses = []
    instructor_courses = defaultdict(list)
    
    for keyword in business_keywords:
        print(f"\n=== Testing {keyword} courses ===")
        
        payload = {
            "other": {"srcdb": ""},
            "criteria": [
                {"field": "keyword", "value": keyword}
            ]
        }
        
        try:
            response = requests.post(COURSES_API_URL, json=payload, headers=headers, timeout=30)
            
            if response.status_code == 200:
                data = response.json()
                results = data.get('results', [])
                print(f"Found {len(results)} {keyword} courses")
                
                for course in results[:5]:  # Show first 5 for each department
                    # Extract instructor info
                    instructors = []
                    if course.get('instr'):
                        raw_instructors = course['instr'].split('/')
                        for instr in raw_instructors:
                            instr = instr.strip()
                            if instr and instr != 'Staff' and instr != 'TBA':
                                instructors.append(instr)
                    
                    course_info = {
                        'code': course.get('code', ''),
                        'title': course.get('title', ''),
                        'crn': course.get('crn', ''),
                        'section': course.get('section', course.get('no', '')),
                        'instructors': instructors,
                        'status': course.get('stat', ''),
                        'meeting_times': course.get('meetingTimes', '[]'),
                    }
                    
                    print(f"  {course_info['code']} - {course_info['title'][:40]}...")
                    print(f"    CRN: {course_info['crn']}, Section: {course_info['section']}")
                    print(f"    Instructors: {', '.join(instructors) if instructors else 'Staff/TBA'}")
                    print(f"    Status: {course_info['status']}")
                    
                    # Track instructor-course relationships
                    for instructor in instructors:
                        instructor_courses[instructor].append({
                            'code': course_info['code'],
                            'title': course_info['title'],
                            'crn': course_info['crn']
                        })
                    
                    all_business_courses.append(course_info)
                
                if len(results) > 5:
                    print(f"  ... and {len(results) - 5} more courses")
                
            else:
                print(f"Error: API returned status {response.status_code}")
                
        except Exception as e:
            print(f"Error testing {keyword}: {e}")
    
    print(f"\n=== Summary ===")
    print(f"Total business courses found: {len(all_business_courses)}")
    print(f"Unique instructors found: {len(instructor_courses)}")
    
    # Show instructor summary
    print(f"\n=== Top Instructors by Course Count ===")
    sorted_instructors = sorted(instructor_courses.items(), key=lambda x: len(x[1]), reverse=True)
    for instructor, courses in sorted_instructors[:10]:
        print(f"  {instructor}: {len(courses)} courses")
        for course in courses[:3]:  # Show first 3 courses
            print(f"    - {course['code']}: {course['title'][:30]}...")
        if len(courses) > 3:
            print(f"    ... and {len(courses) - 3} more")
    
    # Test email generation logic
    print(f"\n=== Email Generation Test ===")
    for instructor in list(instructor_courses.keys())[:10]:
        # Simulate the email generation logic from the scraper
        name_parts = instructor.replace(',', '').split()
        if len(name_parts) >= 2:
            first_name = name_parts[0].lower()
            last_name = name_parts[-1].lower()
            
            # Handle initials
            if len(first_name) == 2 and first_name.endswith('.'):
                first_name = first_name[0]
            
            # Remove periods and clean up
            first_name = first_name.replace('.', '')
            last_name = last_name.replace('.', '')
            
            email = f"{first_name}.{last_name}@slu.edu"
            print(f"  {instructor} -> {email}")

if __name__ == "__main__":
    test_business_courses()
