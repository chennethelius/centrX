#!/usr/bin/env python3
"""
Test script to explore the courses.slu.edu API
"""

import requests
import json
import re
from bs4 import BeautifulSoup

COURSES_API_URL = "https://courses.slu.edu/api/?page=fose&route=search"
COURSES_BASE_URL = "https://courses.slu.edu/"

def test_api_structure():
    """Test different API calls to understand the structure"""
    
    headers = {
        'Content-Type': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
        'Referer': COURSES_BASE_URL
    }
    
    # Test 1: Empty search to see what we get
    print("=== Test 1: Empty search ===")
    try:
        empty_payload = {"other": {"srcdb": ""}, "criteria": []}
        response = requests.post(COURSES_API_URL, json=empty_payload, headers=headers, timeout=30)
        print(f"Status: {response.status_code}")
        print(f"Response length: {len(response.text)}")
        
        if response.status_code == 200:
            try:
                data = response.json()
                print(f"JSON keys: {list(data.keys()) if isinstance(data, dict) else 'Not a dict'}")
                if 'results' in data:
                    print(f"Results count: {len(data['results'])}")
                    if data['results']:
                        sample = data['results'][0]
                        print(f"Sample result keys: {list(sample.keys())}")
                        print(f"Sample: {json.dumps(sample, indent=2)[:500]}...")
                else:
                    print(f"Sample response: {json.dumps(data, indent=2)[:500]}...")
            except json.JSONDecodeError:
                print("Response is not valid JSON")
                print(f"Response text: {response.text[:500]}...")
        else:
            print(f"Error response: {response.text}")
    
    except Exception as e:
        print(f"Error in test 1: {e}")
    
    # Test 2: Search for specific course
    print("\n=== Test 2: Search for specific course (ACCT) ===")
    try:
        course_payload = {
            "other": {"srcdb": ""},
            "criteria": [
                {"field": "keyword", "value": "ACCT"}
            ]
        }
        response = requests.post(COURSES_API_URL, json=course_payload, headers=headers, timeout=30)
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            try:
                data = response.json()
                print(f"JSON keys: {list(data.keys()) if isinstance(data, dict) else 'Not a dict'}")
                if 'results' in data:
                    print(f"Results count: {len(data['results'])}")
                else:
                    print(f"Response: {json.dumps(data, indent=2)[:500]}...")
            except json.JSONDecodeError:
                print("Response is not valid JSON")
                print(f"Response text: {response.text[:500]}...")
        else:
            print(f"Error response: {response.text}")
    
    except Exception as e:
        print(f"Error in test 2: {e}")
    
    # Test 3: Examine the main page for clues
    print("\n=== Test 3: Examine main page structure ===")
    try:
        response = requests.get(COURSES_BASE_URL, timeout=30)
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # Look for JavaScript that might reveal API structure
        scripts = soup.find_all('script')
        for script in scripts:
            if script.string and ('criteria' in script.string or 'search' in script.string):
                print("Found relevant script content:")
                print(script.string[:500] + "..." if len(script.string) > 500 else script.string)
                break
        
        # Look for form fields that might indicate search parameters
        inputs = soup.find_all('input')
        selects = soup.find_all('select')
        
        print(f"Found {len(inputs)} input fields and {len(selects)} select fields")
        
        for inp in inputs[:10]:  # First 10 inputs
            name = inp.get('name', '')
            input_id = inp.get('id', '')
            if name or input_id:
                print(f"Input: name='{name}', id='{input_id}', type='{inp.get('type', '')}'")
        
        for sel in selects[:5]:  # First 5 selects
            name = sel.get('name', '')
            select_id = sel.get('id', '')
            if name or select_id:
                print(f"Select: name='{name}', id='{select_id}'")
                options = sel.find_all('option')[:3]  # First 3 options
                for opt in options:
                    print(f"  Option: value='{opt.get('value', '')}', text='{opt.get_text()[:30]}'")
    
    except Exception as e:
        print(f"Error in test 3: {e}")

if __name__ == "__main__":
    test_api_structure()
