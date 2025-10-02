#!/usr/bin/env python3
"""
Quick script to check Firestore data
"""
from google.cloud import firestore

db = firestore.Client()

print("=== TEACHERS DIRECTORY ===")
teachers_ref = db.collection('teachers_dir')
teachers = teachers_ref.limit(5).stream()

for i, doc in enumerate(teachers):
    data = doc.to_dict()
    print(f"{i+1}. {doc.id}")
    print(f"   Email: {data.get('email')}")
    print(f"   Name: {data.get('fullName')}")
    print(f"   Dept: {data.get('department')}")
    print()

print("\n=== COURSES CATALOG ===")
courses_ref = db.collection('courses_catalog')
courses = courses_ref.limit(5).stream()

for i, doc in enumerate(courses):
    data = doc.to_dict()
    print(f"{i+1}. {doc.id}")
    print(f"   Code: {data.get('code')}")
    print(f"   Title: {data.get('title')}")
    print(f"   Dept: {data.get('dept')}")
    print()

# Get counts
teachers_count = len(list(db.collection('teachers_dir').stream()))
courses_count = len(list(db.collection('courses_catalog').stream()))

print(f"\n=== SUMMARY ===")
print(f"Total Teachers: {teachers_count}")
print(f"Total Courses: {courses_count}")
