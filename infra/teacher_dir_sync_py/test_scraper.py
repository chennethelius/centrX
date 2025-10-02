#!/usr/bin/env python3
"""
Test the updated scraper functions with a small sample
"""

import requests
import json
import re
from bs4 import BeautifulSoup

COURSES_API_URL = "https://courses.slu.edu/api/?page=fose&route=search"
COURSES_BASE_URL = "https://courses.slu.edu/"

def test_scraper_logic():
    """Test the scraper logic with actual API data"""
    
    try:
        headers = {
            'Content-Type': 'application/json',
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
            'Referer': COURSES_BASE_URL
        }
        
        # Search for a specific department to get a smaller sample
        search_payload = {
            "other": {"srcdb": ""},
            "criteria": [
                {"field": "keyword", "value": "CSCI"}  # Computer Science courses
            ]
        }
        
        print("Testing scraper logic with CSCI courses...")
        response = requests.post(COURSES_API_URL, json=search_payload, headers=headers, timeout=30)
        
        if response.status_code != 200:
            print(f"Error: API returned status {response.status_code}")
            return
        
        data = response.json()
        results = data.get('results', [])
        
        print(f"Found {len(results)} CSCI course sessions")
        
        courses_with_sessions = []
        
        for course_entry in results[:5]:  # Test with first 5 courses
            course_code = course_entry.get('code', '')
            course_title = course_entry.get('title', '')
            
            # Extract department from course code
            dept_match = re.match(r'^([A-Z]+)', course_code)
            dept = dept_match.group(1) if dept_match else 'UNKNOWN'
            
            # Extract instructor information from the 'instr' field
            instructor_names = []
            if course_entry.get('instr'):
                raw_instructors = course_entry['instr'].split('/')
                for instr in raw_instructors:
                    instr = instr.strip()
                    if instr and instr not in ['Staff', 'TBA']:
                        instructor_names.append(instr)
            
            print(f"\nCourse: {course_code} - {course_title}")
            print(f"Department: {dept}")
            print(f"Instructors: {instructor_names}")
            print(f"CRN: {course_entry.get('crn', '')}")
            print(f"Section: {course_entry.get('section', course_entry.get('no', ''))}")
            print(f"Status: {course_entry.get('stat', 'A')}")
            
            # Generate email addresses for instructors
            for instructor_name in instructor_names:
                clean_name = re.sub(r'\s*\([^)]*\)', '', instructor_name).strip()
                name_parts = clean_name.split()
                
                if len(name_parts) >= 2:
                    first = name_parts[0].lower()
                    last = name_parts[-1].lower()
                    first = re.sub(r'^(dr|prof|professor)\.?', '', first)
                    email = f"{first}.{last}@slu.edu"
                    print(f"  {instructor_name} -> {email}")
        
        print(f"\nScaper test completed successfully!")
        
    except Exception as e:
        print(f"Error in scraper test: {e}")

if __name__ == "__main__":
    test_scraper_logic()
