#!/usr/bin/env python3
"""
Test the full scraper functionality
"""

import requests
import json
import sys
import os

# Add the parent directory to the path so we can import the main module
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

def test_complete_scraper():
    """Test the full scraper workflow"""
    
    # Import the functions from main.py
    try:
        from main import scrape_courses_from_api
        print("✓ Successfully imported scraper functions")
    except ImportError as e:
        print(f"✗ Failed to import functions: {e}")
        return
    
    # Test course scraping (with a limit to avoid too much output)
    print("\n=== Testing Course Scraping ===")
    try:
        courses = scrape_courses_from_api()
        print(f"✓ Successfully scraped {len(courses)} course sessions")
        
        if courses:
            # Show a sample of the data
            sample = courses[0]
            print(f"\nSample course session:")
            for key, value in sample.items():
                print(f"  {key}: {value}")
                
            # Count unique instructors
            instructors = set()
            for course in courses[:100]:  # Check first 100 to avoid too much processing
                if course.get('instructor_name') and course['instructor_name'] not in ['Staff', 'TBA']:
                    instructors.add(course['instructor_name'])
            
            print(f"\nFound {len(instructors)} unique instructors in first 100 sessions")
            print("Sample instructors:")
            for instr in list(instructors)[:10]:
                print(f"  - {instr}")
        
    except Exception as e:
        print(f"✗ Course scraping failed: {e}")
        import traceback
        traceback.print_exc()
    
    print("\n=== Scraper Test Complete ===")

if __name__ == "__main__":
    test_complete_scraper()
