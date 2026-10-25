import "dotenv/config";
import express from "express";
import http from "http";
import path from "path";
import fs from "fs";
import cors from "cors";
import { WebSocketServer, WebSocket } from "ws";

const app = express();
const server = http.createServer(app);
const PORT = 3000;

app.use(cors());
app.use(express.json({ limit: "25mb" }));
app.use(express.urlencoded({ extended: true, limit: "25mb" }));

// =========================================================
// IN-MEMORY & PERSISTENT DATABASE STORE
// =========================================================

// Categories
const CATEGORIES = [
  { id: "criminal", name: "Criminal Law" },
  { id: "family", name: "Family Law" },
  { id: "property", name: "Property Law" },
  { id: "corporate", name: "Corporate Law" },
  { id: "civil", name: "Civil Law" },
  { id: "financial", name: "Financial Law" },
  { id: "cyber", name: "Cyber Law" },
  { id: "labour", name: "Labour & Employment Law" },
  { id: "taxation", name: "Taxation & GST" },
  { id: "constitutional", name: "Constitutional Law" },
  { id: "consumer", name: "Consumer Protection" },
  { id: "intellectual_property", name: "Intellectual Property" },
  { id: "environmental", name: "Environmental Law" }
];

// Pre-seeded 49 Indian Lawyers
// Exactly 13 lawyers with ₹1 consultation fee (one in each category)
// Exactly 36 lawyers with normal consultation fees (₹500 to ₹2500)
// One lawyer MUST be: Adv. Abhishek Sarangale
const INITIAL_LAWYERS = [
  {
    "id": "lawyer-1",
    "legacy_id": 1,
    "linked_user_id": "lawyer-user-1",
    "test_route_user_id": "lawyer-user-1",
    "display_name": "Adv. Tanvi Patil",
    "gender": "Female",
    "legal_category": "criminal",
    "years_experience": 14,
    "seed_rating": 4.9,
    "seed_review_count": 88,
    "consultation_fee": 1,
    "locality": "Shivaji Nagar",
    "city": "Pune",
    "state": "Maharashtra",
    "languages": [
      "Marathi",
      "Hindi",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Sana Qureshi.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-2",
    "legacy_id": 2,
    "linked_user_id": "lawyer-user-2",
    "test_route_user_id": "lawyer-user-2",
    "display_name": "Adv. Harsh Mehta",
    "gender": "Male",
    "legal_category": "criminal",
    "years_experience": 16,
    "seed_rating": 4.9,
    "seed_review_count": 82,
    "consultation_fee": 1200,
    "locality": "Fort",
    "city": "Mumbai",
    "state": "Maharashtra",
    "languages": [
      "Marathi",
      "Hindi",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Harsh Mehta.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-3",
    "legacy_id": 3,
    "linked_user_id": "lawyer-user-3",
    "test_route_user_id": "lawyer-user-3",
    "display_name": "Adv. Nikhil Patil",
    "gender": "Male",
    "legal_category": "criminal",
    "years_experience": 13,
    "seed_rating": 4.8,
    "seed_review_count": 64,
    "consultation_fee": 1100,
    "locality": "Civil Lines",
    "city": "Nagpur",
    "state": "Maharashtra",
    "languages": [
      "Marathi",
      "Hindi",
      "English"
    ],
    "availability": "tomorrow",
    "profile_photo_path": "Nikhil Patil.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-4",
    "legacy_id": 4,
    "linked_user_id": "lawyer-user-4",
    "test_route_user_id": "lawyer-user-4",
    "display_name": "Adv. Shreya Jain",
    "gender": "Female",
    "legal_category": "criminal",
    "years_experience": 10,
    "seed_rating": 4.7,
    "seed_review_count": 49,
    "consultation_fee": 950,
    "locality": "Arera Colony",
    "city": "Bhopal",
    "state": "Madhya Pradesh",
    "languages": [
      "Hindi",
      "English"
    ],
    "availability": "week",
    "profile_photo_path": "Shreya Jain.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-5",
    "legacy_id": 5,
    "linked_user_id": "lawyer-user-5",
    "test_route_user_id": "lawyer-user-5",
    "display_name": "Adv. Pradeep Verma",
    "gender": "Male",
    "legal_category": "criminal",
    "years_experience": 15,
    "seed_rating": 4.9,
    "seed_review_count": 72,
    "consultation_fee": 1300,
    "locality": "Gomti Nagar",
    "city": "Lucknow",
    "state": "Uttar Pradesh",
    "languages": [
      "Hindi",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Aman Kapoor.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-6",
    "legacy_id": 6,
    "linked_user_id": "lawyer-user-6",
    "test_route_user_id": "lawyer-user-6",
    "display_name": "Adv. Rajesh Khanna",
    "gender": "Male",
    "legal_category": "criminal",
    "years_experience": 18,
    "seed_rating": 4.8,
    "seed_review_count": 85,
    "consultation_fee": 1400,
    "locality": "Saket",
    "city": "Delhi",
    "state": "NCR",
    "languages": [
      "Hindi",
      "Punjabi",
      "English"
    ],
    "availability": "tomorrow",
    "profile_photo_path": "Akash Reddy.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-7",
    "legacy_id": 7,
    "linked_user_id": "lawyer-user-7",
    "test_route_user_id": "lawyer-user-7",
    "display_name": "Adv. Manisha Kulkarni",
    "gender": "Female",
    "legal_category": "criminal",
    "years_experience": 12,
    "seed_rating": 4.9,
    "seed_review_count": 63,
    "consultation_fee": 1000,
    "locality": "Deccan Gymkhana",
    "city": "Pune",
    "state": "Maharashtra",
    "languages": [
      "Marathi",
      "Hindi",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Aarti More.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-8",
    "legacy_id": 8,
    "linked_user_id": "lawyer-user-8",
    "test_route_user_id": "lawyer-user-8",
    "display_name": "Adv. Deepak Shinde",
    "gender": "Male",
    "legal_category": "criminal",
    "years_experience": 11,
    "seed_rating": 4.7,
    "seed_review_count": 54,
    "consultation_fee": 1150,
    "locality": "Panchpakhadi",
    "city": "Thane",
    "state": "Maharashtra",
    "languages": [
      "Marathi",
      "Hindi",
      "English"
    ],
    "availability": "week",
    "profile_photo_path": "Aditya Singh.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-9",
    "legacy_id": 9,
    "linked_user_id": "lawyer-user-9",
    "test_route_user_id": "lawyer-user-9",
    "display_name": "Adv. Aarti More",
    "gender": "Female",
    "legal_category": "family",
    "years_experience": 11,
    "seed_rating": 4.8,
    "seed_review_count": 64,
    "consultation_fee": 1,
    "locality": "Bandra West",
    "city": "Mumbai",
    "state": "Maharashtra",
    "languages": [
      "Marathi",
      "Hindi",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Aarti More.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-10",
    "legacy_id": 10,
    "linked_user_id": "lawyer-user-10",
    "test_route_user_id": "lawyer-user-10",
    "display_name": "Adv. Isha Banerjee",
    "gender": "Female",
    "legal_category": "family",
    "years_experience": 12,
    "seed_rating": 4.8,
    "seed_review_count": 61,
    "consultation_fee": 900,
    "locality": "Salt Lake",
    "city": "Kolkata",
    "state": "West Bengal",
    "languages": [
      "Bengali",
      "Hindi",
      "English"
    ],
    "availability": "tomorrow",
    "profile_photo_path": "Isha Banerjee.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-11",
    "legacy_id": 11,
    "linked_user_id": "lawyer-user-11",
    "test_route_user_id": "lawyer-user-11",
    "display_name": "Adv. Nisha Bose",
    "gender": "Female",
    "legal_category": "family",
    "years_experience": 15,
    "seed_rating": 4.9,
    "seed_review_count": 75,
    "consultation_fee": 1000,
    "locality": "Alipore",
    "city": "Kolkata",
    "state": "West Bengal",
    "languages": [
      "Bengali",
      "Hindi",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Nisha Bose.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-12",
    "legacy_id": 12,
    "linked_user_id": "lawyer-user-12",
    "test_route_user_id": "lawyer-user-12",
    "display_name": "Adv. Shruti Rao",
    "gender": "Female",
    "legal_category": "family",
    "years_experience": 13,
    "seed_rating": 4.8,
    "seed_review_count": 58,
    "consultation_fee": 1050,
    "locality": "Koramangala",
    "city": "Bengaluru",
    "state": "Karnataka",
    "languages": [
      "Kannada",
      "English",
      "Hindi"
    ],
    "availability": "week",
    "profile_photo_path": "Shruti Rao.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-13",
    "legacy_id": 13,
    "linked_user_id": "lawyer-user-13",
    "test_route_user_id": "lawyer-user-13",
    "display_name": "Adv. Smita Deshpande",
    "gender": "Female",
    "legal_category": "family",
    "years_experience": 14,
    "seed_rating": 4.9,
    "seed_review_count": 68,
    "consultation_fee": 1100,
    "locality": "Dadar",
    "city": "Mumbai",
    "state": "Maharashtra",
    "languages": [
      "Marathi",
      "Hindi",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Ananya Rao.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-14",
    "legacy_id": 14,
    "linked_user_id": "lawyer-user-14",
    "test_route_user_id": "lawyer-user-14",
    "display_name": "Adv. Aniruddh Sengupta",
    "gender": "Male",
    "legal_category": "family",
    "years_experience": 13,
    "seed_rating": 4.8,
    "seed_review_count": 59,
    "consultation_fee": 950,
    "locality": "Park Street",
    "city": "Kolkata",
    "state": "West Bengal",
    "languages": [
      "Bengali",
      "English",
      "Hindi"
    ],
    "availability": "tomorrow",
    "profile_photo_path": "Arjun Mehta.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-15",
    "legacy_id": 15,
    "linked_user_id": "lawyer-user-15",
    "test_route_user_id": "lawyer-user-15",
    "display_name": "Adv. Pooja Sundaram",
    "gender": "Female",
    "legal_category": "family",
    "years_experience": 16,
    "seed_rating": 4.9,
    "seed_review_count": 81,
    "consultation_fee": 1200,
    "locality": "Anna Nagar",
    "city": "Chennai",
    "state": "Tamil Nadu",
    "languages": [
      "Tamil",
      "English",
      "Hindi"
    ],
    "availability": "today",
    "profile_photo_path": "Anjali Rao.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-16",
    "legacy_id": 16,
    "linked_user_id": "lawyer-user-16",
    "test_route_user_id": "lawyer-user-16",
    "display_name": "Adv. Geeta Pillai",
    "gender": "Female",
    "legal_category": "family",
    "years_experience": 10,
    "seed_rating": 4.7,
    "seed_review_count": 46,
    "consultation_fee": 850,
    "locality": "Ernakulam",
    "city": "Kochi",
    "state": "Kerala",
    "languages": [
      "Malayalam",
      "English",
      "Hindi"
    ],
    "availability": "week",
    "profile_photo_path": "Rohan Deshmukh.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-17",
    "legacy_id": 17,
    "linked_user_id": "lawyer-user-17",
    "test_route_user_id": "lawyer-user-17",
    "display_name": "Adv. Aditya Singh",
    "gender": "Male",
    "legal_category": "property",
    "years_experience": 12,
    "seed_rating": 4.7,
    "seed_review_count": 52,
    "consultation_fee": 1,
    "locality": "Connaught Place",
    "city": "Delhi",
    "state": "NCR",
    "languages": [
      "Hindi",
      "English"
    ],
    "availability": "tomorrow",
    "profile_photo_path": "Aditya Singh.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-18",
    "legacy_id": 18,
    "linked_user_id": "lawyer-user-18",
    "test_route_user_id": "lawyer-user-18",
    "display_name": "Adv. Kavya Patil",
    "gender": "Female",
    "legal_category": "property",
    "years_experience": 9,
    "seed_rating": 4.7,
    "seed_review_count": 45,
    "consultation_fee": 800,
    "locality": "Kothrud",
    "city": "Pune",
    "state": "Maharashtra",
    "languages": [
      "Marathi",
      "Hindi",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Kavya Patil.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-19",
    "legacy_id": 19,
    "linked_user_id": "lawyer-user-19",
    "test_route_user_id": "lawyer-user-19",
    "display_name": "Adv. Priya Sharma",
    "gender": "Female",
    "legal_category": "property",
    "years_experience": 14,
    "seed_rating": 4.8,
    "seed_review_count": 67,
    "consultation_fee": 1200,
    "locality": "MP Nagar",
    "city": "Bhopal",
    "state": "Madhya Pradesh",
    "languages": [
      "Hindi",
      "English"
    ],
    "availability": "tomorrow",
    "profile_photo_path": "Priya Sharma.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-20",
    "legacy_id": 20,
    "linked_user_id": "lawyer-user-20",
    "test_route_user_id": "lawyer-user-20",
    "display_name": "Adv. Siddharth Jain",
    "gender": "Male",
    "legal_category": "property",
    "years_experience": 15,
    "seed_rating": 4.9,
    "seed_review_count": 79,
    "consultation_fee": 1400,
    "locality": "Bodakdev",
    "city": "Ahmedabad",
    "state": "Gujarat",
    "languages": [
      "Gujarati",
      "Hindi",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Siddharth Jain.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-21",
    "legacy_id": 21,
    "linked_user_id": "lawyer-user-21",
    "test_route_user_id": "lawyer-user-21",
    "display_name": "Adv. Rameshwar Kulkarni",
    "gender": "Male",
    "legal_category": "property",
    "years_experience": 17,
    "seed_rating": 4.9,
    "seed_review_count": 92,
    "consultation_fee": 1350,
    "locality": "Viman Nagar",
    "city": "Pune",
    "state": "Maharashtra",
    "languages": [
      "Marathi",
      "Hindi",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Harsh Mehta.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-22",
    "legacy_id": 22,
    "linked_user_id": "lawyer-user-22",
    "test_route_user_id": "lawyer-user-22",
    "display_name": "Adv. Vandana Chawla",
    "gender": "Female",
    "legal_category": "property",
    "years_experience": 13,
    "seed_rating": 4.8,
    "seed_review_count": 67,
    "consultation_fee": 1100,
    "locality": "Dwarka",
    "city": "Delhi",
    "state": "NCR",
    "languages": [
      "Hindi",
      "English",
      "Punjabi"
    ],
    "availability": "tomorrow",
    "profile_photo_path": "Priya Sharma.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-23",
    "legacy_id": 23,
    "linked_user_id": "lawyer-user-23",
    "test_route_user_id": "lawyer-user-23",
    "display_name": "Adv. Suresh Hegde",
    "gender": "Male",
    "legal_category": "property",
    "years_experience": 15,
    "seed_rating": 4.8,
    "seed_review_count": 74,
    "consultation_fee": 1250,
    "locality": "Jayanagar",
    "city": "Bengaluru",
    "state": "Karnataka",
    "languages": [
      "Kannada",
      "English",
      "Hindi"
    ],
    "availability": "today",
    "profile_photo_path": "Sneha Iyer.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-24",
    "legacy_id": 24,
    "linked_user_id": "lawyer-user-24",
    "test_route_user_id": "lawyer-user-24",
    "display_name": "Adv. Alok Tripathi",
    "gender": "Male",
    "legal_category": "property",
    "years_experience": 11,
    "seed_rating": 4.7,
    "seed_review_count": 49,
    "consultation_fee": 900,
    "locality": "Sigra",
    "city": "Varanasi",
    "state": "Uttar Pradesh",
    "languages": [
      "Hindi",
      "English"
    ],
    "availability": "week",
    "profile_photo_path": "Armaan Sheikh.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-25",
    "legacy_id": 25,
    "linked_user_id": "lawyer-user-25",
    "test_route_user_id": "lawyer-user-25",
    "display_name": "Adv. Akash Reddy",
    "gender": "Male",
    "legal_category": "corporate",
    "years_experience": 10,
    "seed_rating": 4.9,
    "seed_review_count": 73,
    "consultation_fee": 1,
    "locality": "Hitec City",
    "city": "Hyderabad",
    "state": "Telangana",
    "languages": [
      "Telugu",
      "English",
      "Hindi"
    ],
    "availability": "today",
    "profile_photo_path": "Akash Reddy.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-26",
    "legacy_id": 26,
    "linked_user_id": "lawyer-user-26",
    "test_route_user_id": "lawyer-user-26",
    "display_name": "Adv. Karan Malhotra",
    "gender": "Male",
    "legal_category": "corporate",
    "years_experience": 14,
    "seed_rating": 4.9,
    "seed_review_count": 79,
    "consultation_fee": 1500,
    "locality": "Barakhamba Road",
    "city": "Delhi",
    "state": "NCR",
    "languages": [
      "Hindi",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Karan Malhotra.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-27",
    "legacy_id": 27,
    "linked_user_id": "lawyer-user-27",
    "test_route_user_id": "lawyer-user-27",
    "display_name": "Adv. Radhika Iyer",
    "gender": "Female",
    "legal_category": "corporate",
    "years_experience": 16,
    "seed_rating": 4.9,
    "seed_review_count": 86,
    "consultation_fee": 2000,
    "locality": "T Nagar",
    "city": "Chennai",
    "state": "Tamil Nadu",
    "languages": [
      "Tamil",
      "English",
      "Hindi"
    ],
    "availability": "tomorrow",
    "profile_photo_path": "Radhika Iyer.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-28",
    "legacy_id": 28,
    "linked_user_id": "lawyer-user-28",
    "test_route_user_id": "lawyer-user-28",
    "display_name": "Adv. Siddharth Rao",
    "gender": "Male",
    "legal_category": "corporate",
    "years_experience": 17,
    "seed_rating": 5,
    "seed_review_count": 95,
    "consultation_fee": 2200,
    "locality": "Indiranagar",
    "city": "Bengaluru",
    "state": "Karnataka",
    "languages": [
      "Kannada",
      "English",
      "Hindi"
    ],
    "availability": "today",
    "profile_photo_path": "Siddharth Rao.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-29",
    "legacy_id": 29,
    "linked_user_id": "lawyer-user-29",
    "test_route_user_id": "lawyer-user-29",
    "display_name": "Adv. Gaurav Singhania",
    "gender": "Male",
    "legal_category": "corporate",
    "years_experience": 15,
    "seed_rating": 4.9,
    "seed_review_count": 88,
    "consultation_fee": 1800,
    "locality": "BKC",
    "city": "Mumbai",
    "state": "Maharashtra",
    "languages": [
      "Hindi",
      "English",
      "Gujarati"
    ],
    "availability": "today",
    "profile_photo_path": "Sameer Joshi.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-30",
    "legacy_id": 30,
    "linked_user_id": "lawyer-user-30",
    "test_route_user_id": "lawyer-user-30",
    "display_name": "Adv. Meenakshi Menon",
    "gender": "Female",
    "legal_category": "corporate",
    "years_experience": 18,
    "seed_rating": 5,
    "seed_review_count": 104,
    "consultation_fee": 2100,
    "locality": "Whitefield",
    "city": "Bengaluru",
    "state": "Karnataka",
    "languages": [
      "Malayalam",
      "English",
      "Hindi"
    ],
    "availability": "tomorrow",
    "profile_photo_path": "Shreya Jain.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-31",
    "legacy_id": 31,
    "linked_user_id": "lawyer-user-31",
    "test_route_user_id": "lawyer-user-31",
    "display_name": "Adv. Vikramaditya Sen",
    "gender": "Male",
    "legal_category": "corporate",
    "years_experience": 13,
    "seed_rating": 4.8,
    "seed_review_count": 71,
    "consultation_fee": 1600,
    "locality": "DLF Phase 5",
    "city": "Gurugram",
    "state": "Haryana",
    "languages": [
      "Hindi",
      "English",
      "Bengali"
    ],
    "availability": "today",
    "profile_photo_path": "Siddharth Jain.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-32",
    "legacy_id": 32,
    "linked_user_id": "lawyer-user-32",
    "test_route_user_id": "lawyer-user-32",
    "display_name": "Adv. Natasha Godrej",
    "gender": "Female",
    "legal_category": "corporate",
    "years_experience": 14,
    "seed_rating": 4.9,
    "seed_review_count": 83,
    "consultation_fee": 1950,
    "locality": "Nariman Point",
    "city": "Mumbai",
    "state": "Maharashtra",
    "languages": [
      "English",
      "Hindi",
      "Marathi"
    ],
    "availability": "week",
    "profile_photo_path": "Radhika Iyer.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-33",
    "legacy_id": 33,
    "linked_user_id": "lawyer-user-33",
    "test_route_user_id": "lawyer-user-33",
    "display_name": "Adv. Aman Kapoor",
    "gender": "Male",
    "legal_category": "civil",
    "years_experience": 9,
    "seed_rating": 4.6,
    "seed_review_count": 41,
    "consultation_fee": 1,
    "locality": "Sector 17",
    "city": "Chandigarh",
    "state": "Punjab",
    "languages": [
      "Hindi",
      "Punjabi",
      "English"
    ],
    "availability": "week",
    "profile_photo_path": "Aman Kapoor.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-34",
    "legacy_id": 34,
    "linked_user_id": "lawyer-user-34",
    "test_route_user_id": "lawyer-user-34",
    "display_name": "Adv. Kunal Jain",
    "gender": "Male",
    "legal_category": "civil",
    "years_experience": 11,
    "seed_rating": 4.6,
    "seed_review_count": 39,
    "consultation_fee": 750,
    "locality": "Vijay Nagar",
    "city": "Indore",
    "state": "Madhya Pradesh",
    "languages": [
      "Hindi",
      "English"
    ],
    "availability": "tomorrow",
    "profile_photo_path": "Kunal Jain.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-35",
    "legacy_id": 35,
    "linked_user_id": "lawyer-user-35",
    "test_route_user_id": "lawyer-user-35",
    "display_name": "Adv. Rahul Joshi",
    "gender": "Male",
    "legal_category": "civil",
    "years_experience": 10,
    "seed_rating": 4.7,
    "seed_review_count": 51,
    "consultation_fee": 800,
    "locality": "Sadashiv Peth",
    "city": "Pune",
    "state": "Maharashtra",
    "languages": [
      "Marathi",
      "Hindi",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Rahul Joshi.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-36",
    "legacy_id": 36,
    "linked_user_id": "lawyer-user-36",
    "test_route_user_id": "lawyer-user-36",
    "display_name": "Adv. Sneha Iyer",
    "gender": "Female",
    "legal_category": "civil",
    "years_experience": 12,
    "seed_rating": 4.8,
    "seed_review_count": 62,
    "consultation_fee": 850,
    "locality": "Adyar",
    "city": "Chennai",
    "state": "Tamil Nadu",
    "languages": [
      "Tamil",
      "English",
      "Hindi"
    ],
    "availability": "tomorrow",
    "profile_photo_path": "Sneha Iyer.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-37",
    "legacy_id": 37,
    "linked_user_id": "lawyer-user-37",
    "test_route_user_id": "lawyer-user-37",
    "display_name": "Adv. Bhaskar Nambiar",
    "gender": "Male",
    "legal_category": "civil",
    "years_experience": 14,
    "seed_rating": 4.8,
    "seed_review_count": 62,
    "consultation_fee": 900,
    "locality": "Kaloor",
    "city": "Kochi",
    "state": "Kerala",
    "languages": [
      "Malayalam",
      "English",
      "Hindi"
    ],
    "availability": "today",
    "profile_photo_path": "Amit Desai.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-38",
    "legacy_id": 38,
    "linked_user_id": "lawyer-user-38",
    "test_route_user_id": "lawyer-user-38",
    "display_name": "Adv. Divya Narang",
    "gender": "Female",
    "legal_category": "civil",
    "years_experience": 10,
    "seed_rating": 4.7,
    "seed_review_count": 48,
    "consultation_fee": 800,
    "locality": "Mansarovar",
    "city": "Jaipur",
    "state": "Rajasthan",
    "languages": [
      "Hindi",
      "English"
    ],
    "availability": "tomorrow",
    "profile_photo_path": "Kunal Jain.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-39",
    "legacy_id": 39,
    "linked_user_id": "lawyer-user-39",
    "test_route_user_id": "lawyer-user-39",
    "display_name": "Adv. Sanjay Gadkari",
    "gender": "Male",
    "legal_category": "civil",
    "years_experience": 13,
    "seed_rating": 4.8,
    "seed_review_count": 55,
    "consultation_fee": 850,
    "locality": "Dharampeth",
    "city": "Nagpur",
    "state": "Maharashtra",
    "languages": [
      "Marathi",
      "Hindi",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Sameer Khan.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-40",
    "legacy_id": 40,
    "linked_user_id": "lawyer-user-40",
    "test_route_user_id": "lawyer-user-40",
    "display_name": "Adv. Sunita Mahapatra",
    "gender": "Female",
    "legal_category": "civil",
    "years_experience": 11,
    "seed_rating": 4.7,
    "seed_review_count": 43,
    "consultation_fee": 750,
    "locality": "Saheed Nagar",
    "city": "Bhubaneswar",
    "state": "Odisha",
    "languages": [
      "Odia",
      "Hindi",
      "English"
    ],
    "availability": "week",
    "profile_photo_path": "Karan Malhotra.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-41",
    "legacy_id": 41,
    "linked_user_id": "lawyer-user-41",
    "test_route_user_id": "lawyer-user-41",
    "display_name": "Adv. Amit Desai",
    "gender": "Male",
    "legal_category": "financial",
    "years_experience": 15,
    "seed_rating": 4.8,
    "seed_review_count": 67,
    "consultation_fee": 1,
    "locality": "Ashram Road",
    "city": "Ahmedabad",
    "state": "Gujarat",
    "languages": [
      "Gujarati",
      "Hindi",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Amit Desai.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-42",
    "legacy_id": 42,
    "linked_user_id": "lawyer-user-42",
    "test_route_user_id": "lawyer-user-42",
    "display_name": "Adv. Komal Shah",
    "gender": "Female",
    "legal_category": "financial",
    "years_experience": 13,
    "seed_rating": 4.8,
    "seed_review_count": 58,
    "consultation_fee": 1100,
    "locality": "Navrangpura",
    "city": "Ahmedabad",
    "state": "Gujarat",
    "languages": [
      "Gujarati",
      "Hindi",
      "English"
    ],
    "availability": "week",
    "profile_photo_path": "Komal Shah.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-43",
    "legacy_id": 43,
    "linked_user_id": "lawyer-user-43",
    "test_route_user_id": "lawyer-user-43",
    "display_name": "Adv. Rajiv Sethi",
    "gender": "Male",
    "legal_category": "financial",
    "years_experience": 18,
    "seed_rating": 4.9,
    "seed_review_count": 89,
    "consultation_fee": 1600,
    "locality": "Sector 9",
    "city": "Chandigarh",
    "state": "Punjab",
    "languages": [
      "Hindi",
      "Punjabi",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Rajiv Sethi.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-44",
    "legacy_id": 44,
    "linked_user_id": "lawyer-user-44",
    "test_route_user_id": "lawyer-user-44",
    "display_name": "Adv. Swati Kulkarni",
    "gender": "Female",
    "legal_category": "financial",
    "years_experience": 14,
    "seed_rating": 4.8,
    "seed_review_count": 73,
    "consultation_fee": 1250,
    "locality": "Aundh",
    "city": "Pune",
    "state": "Maharashtra",
    "languages": [
      "Marathi",
      "Hindi",
      "English"
    ],
    "availability": "tomorrow",
    "profile_photo_path": "Swati Kulkarni.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-45",
    "legacy_id": 45,
    "linked_user_id": "lawyer-user-45",
    "test_route_user_id": "lawyer-user-45",
    "display_name": "Adv. Harish Kotak",
    "gender": "Male",
    "legal_category": "financial",
    "years_experience": 16,
    "seed_rating": 4.9,
    "seed_review_count": 78,
    "consultation_fee": 1450,
    "locality": "Nariman Point",
    "city": "Mumbai",
    "state": "Maharashtra",
    "languages": [
      "Gujarati",
      "Hindi",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Komal Shah.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-46",
    "legacy_id": 46,
    "linked_user_id": "lawyer-user-46",
    "test_route_user_id": "lawyer-user-46",
    "display_name": "Adv. Pallavi Srivastava",
    "gender": "Female",
    "legal_category": "financial",
    "years_experience": 12,
    "seed_rating": 4.8,
    "seed_review_count": 65,
    "consultation_fee": 1200,
    "locality": "Sector 62",
    "city": "Noida",
    "state": "Uttar Pradesh",
    "languages": [
      "Hindi",
      "English"
    ],
    "availability": "tomorrow",
    "profile_photo_path": "Meenal Shah.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-47",
    "legacy_id": 47,
    "linked_user_id": "lawyer-user-47",
    "test_route_user_id": "lawyer-user-47",
    "display_name": "Adv. Raghavan Sampath",
    "gender": "Male",
    "legal_category": "financial",
    "years_experience": 17,
    "seed_rating": 4.9,
    "seed_review_count": 84,
    "consultation_fee": 1500,
    "locality": "Nungambakkam",
    "city": "Chennai",
    "state": "Tamil Nadu",
    "languages": [
      "Tamil",
      "English",
      "Hindi"
    ],
    "availability": "today",
    "profile_photo_path": "Aman Kapoor.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-48",
    "legacy_id": 48,
    "linked_user_id": "lawyer-user-48",
    "test_route_user_id": "lawyer-user-48",
    "display_name": "Adv. Madhavan Nair",
    "gender": "Male",
    "legal_category": "financial",
    "years_experience": 14,
    "seed_rating": 4.7,
    "seed_review_count": 57,
    "consultation_fee": 1300,
    "locality": "Statue Junction",
    "city": "Thiruvananthapuram",
    "state": "Kerala",
    "languages": [
      "Malayalam",
      "English",
      "Hindi"
    ],
    "availability": "week",
    "profile_photo_path": "Neha Kapoor.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-49",
    "legacy_id": 49,
    "linked_user_id": "lawyer-user-49",
    "test_route_user_id": "lawyer-user-49",
    "display_name": "Adv. Ananya Rao",
    "gender": "Female",
    "legal_category": "cyber",
    "years_experience": 8,
    "seed_rating": 4.9,
    "seed_review_count": 59,
    "consultation_fee": 1,
    "locality": "Indiranagar",
    "city": "Bengaluru",
    "state": "Karnataka",
    "languages": [
      "Kannada",
      "English",
      "Hindi"
    ],
    "availability": "today",
    "profile_photo_path": "Ananya Rao.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-50",
    "legacy_id": 50,
    "linked_user_id": "lawyer-user-50",
    "test_route_user_id": "lawyer-user-50",
    "display_name": "Adv. Kunal Mehra",
    "gender": "Male",
    "legal_category": "cyber",
    "years_experience": 8,
    "seed_rating": 4.8,
    "seed_review_count": 51,
    "consultation_fee": 1000,
    "locality": "Cyber City",
    "city": "Gurugram",
    "state": "Haryana",
    "languages": [
      "Hindi",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Kunal Mehra.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-51",
    "legacy_id": 51,
    "linked_user_id": "lawyer-user-51",
    "test_route_user_id": "lawyer-user-51",
    "display_name": "Adv. Rhea Shah",
    "gender": "Female",
    "legal_category": "cyber",
    "years_experience": 9,
    "seed_rating": 4.8,
    "seed_review_count": 54,
    "consultation_fee": 1100,
    "locality": "Bandra Kurla",
    "city": "Mumbai",
    "state": "Maharashtra",
    "languages": [
      "Gujarati",
      "Hindi",
      "English"
    ],
    "availability": "tomorrow",
    "profile_photo_path": "Rhea Shah.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-52",
    "legacy_id": 52,
    "linked_user_id": "lawyer-user-52",
    "test_route_user_id": "lawyer-user-52",
    "display_name": "Adv. Tanvi Shah",
    "gender": "Female",
    "legal_category": "cyber",
    "years_experience": 10,
    "seed_rating": 4.9,
    "seed_review_count": 68,
    "consultation_fee": 1200,
    "locality": "Andheri West",
    "city": "Mumbai",
    "state": "Maharashtra",
    "languages": [
      "Marathi",
      "Hindi",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Tanvi Shah.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-53",
    "legacy_id": 53,
    "linked_user_id": "lawyer-user-53",
    "test_route_user_id": "lawyer-user-53",
    "display_name": "Adv. Abhinav Saxena",
    "gender": "Male",
    "legal_category": "cyber",
    "years_experience": 11,
    "seed_rating": 4.9,
    "seed_review_count": 76,
    "consultation_fee": 1300,
    "locality": "Gachibowli",
    "city": "Hyderabad",
    "state": "Telangana",
    "languages": [
      "Telugu",
      "Hindi",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Rahul Joshi.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-54",
    "legacy_id": 54,
    "linked_user_id": "lawyer-user-54",
    "test_route_user_id": "lawyer-user-54",
    "display_name": "Adv. Trisha Mukherjee",
    "gender": "Female",
    "legal_category": "cyber",
    "years_experience": 9,
    "seed_rating": 4.8,
    "seed_review_count": 63,
    "consultation_fee": 1150,
    "locality": "Koramangala",
    "city": "Bengaluru",
    "state": "Karnataka",
    "languages": [
      "Bengali",
      "English",
      "Hindi"
    ],
    "availability": "tomorrow",
    "profile_photo_path": "Nandini Shah.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-55",
    "legacy_id": 55,
    "linked_user_id": "lawyer-user-55",
    "test_route_user_id": "lawyer-user-55",
    "display_name": "Adv. Kartik Subramaniam",
    "gender": "Male",
    "legal_category": "cyber",
    "years_experience": 10,
    "seed_rating": 4.9,
    "seed_review_count": 69,
    "consultation_fee": 1250,
    "locality": "Hinjawadi",
    "city": "Pune",
    "state": "Maharashtra",
    "languages": [
      "Tamil",
      "Hindi",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Vikram Kulkarni.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-56",
    "legacy_id": 56,
    "linked_user_id": "lawyer-user-56",
    "test_route_user_id": "lawyer-user-56",
    "display_name": "Adv. Simran Ahluwalia",
    "gender": "Female",
    "legal_category": "cyber",
    "years_experience": 8,
    "seed_rating": 4.7,
    "seed_review_count": 51,
    "consultation_fee": 1050,
    "locality": "Nehru Place",
    "city": "Delhi",
    "state": "NCR",
    "languages": [
      "Hindi",
      "Punjabi",
      "English"
    ],
    "availability": "week",
    "profile_photo_path": "Akash Reddy.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-57",
    "legacy_id": 57,
    "linked_user_id": "lawyer-user-57",
    "test_route_user_id": "lawyer-user-57",
    "display_name": "Adv. Anjali Rao",
    "gender": "Female",
    "legal_category": "labour",
    "years_experience": 13,
    "seed_rating": 4.7,
    "seed_review_count": 48,
    "consultation_fee": 1,
    "locality": "T Nagar",
    "city": "Chennai",
    "state": "Tamil Nadu",
    "languages": [
      "Tamil",
      "English",
      "Hindi"
    ],
    "availability": "tomorrow",
    "profile_photo_path": "Anjali Rao.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-58",
    "legacy_id": 58,
    "linked_user_id": "lawyer-user-58",
    "test_route_user_id": "lawyer-user-58",
    "display_name": "Adv. Meenal Shah",
    "gender": "Female",
    "legal_category": "labour",
    "years_experience": 10,
    "seed_rating": 4.7,
    "seed_review_count": 42,
    "consultation_fee": 850,
    "locality": "Alkapuri",
    "city": "Vadodara",
    "state": "Gujarat",
    "languages": [
      "Gujarati",
      "Hindi",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Meenal Shah.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-59",
    "legacy_id": 59,
    "linked_user_id": "lawyer-user-59",
    "test_route_user_id": "lawyer-user-59",
    "display_name": "Adv. Riya Chatterjee",
    "gender": "Female",
    "legal_category": "labour",
    "years_experience": 11,
    "seed_rating": 4.8,
    "seed_review_count": 56,
    "consultation_fee": 900,
    "locality": "Bhowanipore",
    "city": "Kolkata",
    "state": "West Bengal",
    "languages": [
      "Bengali",
      "Hindi",
      "English"
    ],
    "availability": "tomorrow",
    "profile_photo_path": "Riya Chatterjee.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-60",
    "legacy_id": 60,
    "linked_user_id": "lawyer-user-60",
    "test_route_user_id": "lawyer-user-60",
    "display_name": "Adv. Tara Sen",
    "gender": "Female",
    "legal_category": "labour",
    "years_experience": 12,
    "seed_rating": 4.8,
    "seed_review_count": 60,
    "consultation_fee": 950,
    "locality": "Salt Lake",
    "city": "Kolkata",
    "state": "West Bengal",
    "languages": [
      "Bengali",
      "Hindi",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Tara Sen.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-61",
    "legacy_id": 61,
    "linked_user_id": "lawyer-user-61",
    "test_route_user_id": "lawyer-user-61",
    "display_name": "Adv. Hemant Gokhale",
    "gender": "Male",
    "legal_category": "labour",
    "years_experience": 15,
    "seed_rating": 4.8,
    "seed_review_count": 73,
    "consultation_fee": 1000,
    "locality": "Parel",
    "city": "Mumbai",
    "state": "Maharashtra",
    "languages": [
      "Marathi",
      "Hindi",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Nisha Bose.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-62",
    "legacy_id": 62,
    "linked_user_id": "lawyer-user-62",
    "test_route_user_id": "lawyer-user-62",
    "display_name": "Adv. Sharmila Dasgupta",
    "gender": "Female",
    "legal_category": "labour",
    "years_experience": 12,
    "seed_rating": 4.7,
    "seed_review_count": 56,
    "consultation_fee": 900,
    "locality": "Howrah",
    "city": "Kolkata",
    "state": "West Bengal",
    "languages": [
      "Bengali",
      "Hindi",
      "English"
    ],
    "availability": "tomorrow",
    "profile_photo_path": "Rajiv Sethi.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-63",
    "legacy_id": 63,
    "linked_user_id": "lawyer-user-63",
    "test_route_user_id": "lawyer-user-63",
    "display_name": "Adv. Venkatesh Murthy",
    "gender": "Male",
    "legal_category": "labour",
    "years_experience": 14,
    "seed_rating": 4.8,
    "seed_review_count": 67,
    "consultation_fee": 1050,
    "locality": "Peenya",
    "city": "Bengaluru",
    "state": "Karnataka",
    "languages": [
      "Kannada",
      "English",
      "Hindi"
    ],
    "availability": "today",
    "profile_photo_path": "Aditya Singh.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-64",
    "legacy_id": 64,
    "linked_user_id": "lawyer-user-64",
    "test_route_user_id": "lawyer-user-64",
    "display_name": "Adv. Jaideep Chauhan",
    "gender": "Male",
    "legal_category": "labour",
    "years_experience": 11,
    "seed_rating": 4.6,
    "seed_review_count": 42,
    "consultation_fee": 850,
    "locality": "NIT Faridabad",
    "city": "Faridabad",
    "state": "Haryana",
    "languages": [
      "Hindi",
      "English"
    ],
    "availability": "week",
    "profile_photo_path": "Neha Kulkarni.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-65",
    "legacy_id": 65,
    "linked_user_id": "lawyer-user-65",
    "test_route_user_id": "lawyer-user-65",
    "display_name": "Adv. Arjun Mehta",
    "gender": "Male",
    "legal_category": "taxation",
    "years_experience": 16,
    "seed_rating": 4.9,
    "seed_review_count": 91,
    "consultation_fee": 1,
    "locality": "C-Scheme",
    "city": "Jaipur",
    "state": "Rajasthan",
    "languages": [
      "Hindi",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Arjun Mehta.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-66",
    "legacy_id": 66,
    "linked_user_id": "lawyer-user-66",
    "test_route_user_id": "lawyer-user-66",
    "display_name": "Adv. Meera Reddy",
    "gender": "Female",
    "legal_category": "taxation",
    "years_experience": 15,
    "seed_rating": 4.9,
    "seed_review_count": 77,
    "consultation_fee": 1400,
    "locality": "Banjara Hills",
    "city": "Hyderabad",
    "state": "Telangana",
    "languages": [
      "Telugu",
      "Hindi",
      "English"
    ],
    "availability": "tomorrow",
    "profile_photo_path": "Meera Reddy.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-67",
    "legacy_id": 67,
    "linked_user_id": "lawyer-user-67",
    "test_route_user_id": "lawyer-user-67",
    "display_name": "Adv. Rohan Deshmukh",
    "gender": "Male",
    "legal_category": "taxation",
    "years_experience": 13,
    "seed_rating": 4.8,
    "seed_review_count": 69,
    "consultation_fee": 1350,
    "locality": "College Road",
    "city": "Nashik",
    "state": "Maharashtra",
    "languages": [
      "Marathi",
      "Hindi",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Rohan Deshmukh.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-68",
    "legacy_id": 68,
    "linked_user_id": "lawyer-user-68",
    "test_route_user_id": "lawyer-user-68",
    "display_name": "Adv. Varun Patil",
    "gender": "Male",
    "legal_category": "taxation",
    "years_experience": 11,
    "seed_rating": 4.7,
    "seed_review_count": 55,
    "consultation_fee": 1150,
    "locality": "Samarth Nagar",
    "city": "Aurangabad",
    "state": "Maharashtra",
    "languages": [
      "Marathi",
      "Hindi",
      "English"
    ],
    "availability": "week",
    "profile_photo_path": "Varun Patil.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-69",
    "legacy_id": 69,
    "linked_user_id": "lawyer-user-69",
    "test_route_user_id": "lawyer-user-69",
    "display_name": "Adv. CA Arvind Singhal",
    "gender": "Male",
    "legal_category": "taxation",
    "years_experience": 18,
    "seed_rating": 5,
    "seed_review_count": 98,
    "consultation_fee": 1600,
    "locality": "Connaught Place",
    "city": "Delhi",
    "state": "NCR",
    "languages": [
      "Hindi",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Kunal Mehra.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-70",
    "legacy_id": 70,
    "linked_user_id": "lawyer-user-70",
    "test_route_user_id": "lawyer-user-70",
    "display_name": "Adv. Malini Sundaram",
    "gender": "Female",
    "legal_category": "taxation",
    "years_experience": 16,
    "seed_rating": 4.9,
    "seed_review_count": 82,
    "consultation_fee": 1450,
    "locality": "Mylapore",
    "city": "Chennai",
    "state": "Tamil Nadu",
    "languages": [
      "Tamil",
      "English",
      "Hindi"
    ],
    "availability": "tomorrow",
    "profile_photo_path": "Kavya Patil.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-71",
    "legacy_id": 71,
    "linked_user_id": "lawyer-user-71",
    "test_route_user_id": "lawyer-user-71",
    "display_name": "Adv. Kirit Parekh",
    "gender": "Male",
    "legal_category": "taxation",
    "years_experience": 14,
    "seed_rating": 4.8,
    "seed_review_count": 71,
    "consultation_fee": 1300,
    "locality": "Ring Road",
    "city": "Surat",
    "state": "Gujarat",
    "languages": [
      "Gujarati",
      "Hindi",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Arvind Menon.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-72",
    "legacy_id": 72,
    "linked_user_id": "lawyer-user-72",
    "test_route_user_id": "lawyer-user-72",
    "display_name": "Adv. Ashok Agarwal",
    "gender": "Male",
    "legal_category": "taxation",
    "years_experience": 13,
    "seed_rating": 4.7,
    "seed_review_count": 58,
    "consultation_fee": 1200,
    "locality": "Civil Lines",
    "city": "Kanpur",
    "state": "Uttar Pradesh",
    "languages": [
      "Hindi",
      "English"
    ],
    "availability": "week",
    "profile_photo_path": "Varun Patil.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-73",
    "legacy_id": 73,
    "linked_user_id": "lawyer-user-73",
    "test_route_user_id": "lawyer-user-73",
    "display_name": "Adv. Armaan Sheikh",
    "gender": "Male",
    "legal_category": "constitutional",
    "years_experience": 18,
    "seed_rating": 5,
    "seed_review_count": 104,
    "consultation_fee": 1,
    "locality": "Hazratganj",
    "city": "Lucknow",
    "state": "Uttar Pradesh",
    "languages": [
      "Hindi",
      "Urdu",
      "English"
    ],
    "availability": "week",
    "profile_photo_path": "Armaan Sheikh.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-74",
    "legacy_id": 74,
    "linked_user_id": "lawyer-user-74",
    "test_route_user_id": "lawyer-user-74",
    "display_name": "Adv. Nandini Shah",
    "gender": "Female",
    "legal_category": "constitutional",
    "years_experience": 17,
    "seed_rating": 4.9,
    "seed_review_count": 91,
    "consultation_fee": 1800,
    "locality": "Barakhamba",
    "city": "New Delhi",
    "state": "NCR",
    "languages": [
      "Hindi",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Nandini Shah.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-75",
    "legacy_id": 75,
    "linked_user_id": "lawyer-user-75",
    "test_route_user_id": "lawyer-user-75",
    "display_name": "Adv. Rohan Kapoor",
    "gender": "Male",
    "legal_category": "constitutional",
    "years_experience": 15,
    "seed_rating": 4.8,
    "seed_review_count": 83,
    "consultation_fee": 1750,
    "locality": "Lajpat Nagar",
    "city": "Delhi",
    "state": "NCR",
    "languages": [
      "Hindi",
      "English"
    ],
    "availability": "tomorrow",
    "profile_photo_path": "Rohan Kapoor.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-76",
    "legacy_id": 76,
    "linked_user_id": "lawyer-user-76",
    "test_route_user_id": "lawyer-user-76",
    "display_name": "Adv. Vikram Kulkarni",
    "gender": "Male",
    "legal_category": "constitutional",
    "years_experience": 20,
    "seed_rating": 5,
    "seed_review_count": 120,
    "consultation_fee": 2500,
    "locality": "Churchgate",
    "city": "Mumbai",
    "state": "Maharashtra",
    "languages": [
      "Marathi",
      "Hindi",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Vikram Kulkarni.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-77",
    "legacy_id": 77,
    "linked_user_id": "lawyer-user-77",
    "test_route_user_id": "lawyer-user-77",
    "display_name": "Adv. Feroz Contractor",
    "gender": "Male",
    "legal_category": "constitutional",
    "years_experience": 19,
    "seed_rating": 4.9,
    "seed_review_count": 94,
    "consultation_fee": 2200,
    "locality": "Fort",
    "city": "Mumbai",
    "state": "Maharashtra",
    "languages": [
      "Hindi",
      "Gujarati",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Aarti More.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-78",
    "legacy_id": 78,
    "linked_user_id": "lawyer-user-78",
    "test_route_user_id": "lawyer-user-78",
    "display_name": "Adv. Indira Swaminathan",
    "gender": "Female",
    "legal_category": "constitutional",
    "years_experience": 21,
    "seed_rating": 5,
    "seed_review_count": 112,
    "consultation_fee": 2400,
    "locality": "Tilak Marg",
    "city": "New Delhi",
    "state": "NCR",
    "languages": [
      "Tamil",
      "Hindi",
      "English"
    ],
    "availability": "tomorrow",
    "profile_photo_path": "Isha Banerjee.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-79",
    "legacy_id": 79,
    "linked_user_id": "lawyer-user-79",
    "test_route_user_id": "lawyer-user-79",
    "display_name": "Adv. Birendra Pratap",
    "gender": "Male",
    "legal_category": "constitutional",
    "years_experience": 16,
    "seed_rating": 4.8,
    "seed_review_count": 77,
    "consultation_fee": 1650,
    "locality": "High Court Road",
    "city": "Prayagraj",
    "state": "Uttar Pradesh",
    "languages": [
      "Hindi",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Deepa Nair.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-80",
    "legacy_id": 80,
    "linked_user_id": "lawyer-user-80",
    "test_route_user_id": "lawyer-user-80",
    "display_name": "Adv. Anand Mohan",
    "gender": "Male",
    "legal_category": "constitutional",
    "years_experience": 18,
    "seed_rating": 4.8,
    "seed_review_count": 81,
    "consultation_fee": 1900,
    "locality": "Bailey Road",
    "city": "Patna",
    "state": "Bihar",
    "languages": [
      "Hindi",
      "English"
    ],
    "availability": "week",
    "profile_photo_path": "Shruti Rao.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-81",
    "legacy_id": 81,
    "linked_user_id": "lawyer-user-81",
    "test_route_user_id": "lawyer-user-81",
    "display_name": "Adv. Arvind Menon",
    "gender": "Male",
    "legal_category": "consumer",
    "years_experience": 11,
    "seed_rating": 4.8,
    "seed_review_count": 53,
    "consultation_fee": 1,
    "locality": "Marine Drive",
    "city": "Kochi",
    "state": "Kerala",
    "languages": [
      "Malayalam",
      "English",
      "Hindi"
    ],
    "availability": "tomorrow",
    "profile_photo_path": "Arvind Menon.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-82",
    "legacy_id": 82,
    "linked_user_id": "lawyer-user-82",
    "test_route_user_id": "lawyer-user-82",
    "display_name": "Adv. Naveen Gowda",
    "gender": "Male",
    "legal_category": "consumer",
    "years_experience": 9,
    "seed_rating": 4.7,
    "seed_review_count": 41,
    "consultation_fee": 700,
    "locality": "Jayalakshmipuram",
    "city": "Mysuru",
    "state": "Karnataka",
    "languages": [
      "Kannada",
      "English",
      "Hindi"
    ],
    "availability": "today",
    "profile_photo_path": "Naveen Gowda.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-83",
    "legacy_id": 83,
    "linked_user_id": "lawyer-user-83",
    "test_route_user_id": "lawyer-user-83",
    "display_name": "Adv. Sameer Joshi",
    "gender": "Male",
    "legal_category": "consumer",
    "years_experience": 12,
    "seed_rating": 4.8,
    "seed_review_count": 57,
    "consultation_fee": 850,
    "locality": "Naupada",
    "city": "Thane",
    "state": "Maharashtra",
    "languages": [
      "Marathi",
      "Hindi",
      "English"
    ],
    "availability": "tomorrow",
    "profile_photo_path": "Sameer Joshi.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-84",
    "legacy_id": 84,
    "linked_user_id": "lawyer-user-84",
    "test_route_user_id": "lawyer-user-84",
    "display_name": "Adv. Shalini Verma",
    "gender": "Female",
    "legal_category": "consumer",
    "years_experience": 10,
    "seed_rating": 4.7,
    "seed_review_count": 49,
    "consultation_fee": 800,
    "locality": "Aliganj",
    "city": "Lucknow",
    "state": "Uttar Pradesh",
    "languages": [
      "Hindi",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Rohan Kapoor.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-85",
    "legacy_id": 85,
    "linked_user_id": "lawyer-user-85",
    "test_route_user_id": "lawyer-user-85",
    "display_name": "Adv. Chandrasekharan Pillai",
    "gender": "Male",
    "legal_category": "consumer",
    "years_experience": 13,
    "seed_rating": 4.8,
    "seed_review_count": 63,
    "consultation_fee": 900,
    "locality": "Pattom",
    "city": "Thiruvananthapuram",
    "state": "Kerala",
    "languages": [
      "Malayalam",
      "English",
      "Hindi"
    ],
    "availability": "today",
    "profile_photo_path": "Tara Sen.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-86",
    "legacy_id": 86,
    "linked_user_id": "lawyer-user-86",
    "test_route_user_id": "lawyer-user-86",
    "display_name": "Adv. Rekha Agnihotri",
    "gender": "Female",
    "legal_category": "consumer",
    "years_experience": 10,
    "seed_rating": 4.7,
    "seed_review_count": 52,
    "consultation_fee": 750,
    "locality": "Palasia",
    "city": "Indore",
    "state": "Madhya Pradesh",
    "languages": [
      "Hindi",
      "English"
    ],
    "availability": "tomorrow",
    "profile_photo_path": "Rhea Shah.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-87",
    "legacy_id": 87,
    "linked_user_id": "lawyer-user-87",
    "test_route_user_id": "lawyer-user-87",
    "display_name": "Adv. Girish Hegde",
    "gender": "Male",
    "legal_category": "consumer",
    "years_experience": 12,
    "seed_rating": 4.8,
    "seed_review_count": 58,
    "consultation_fee": 850,
    "locality": "Hampankatta",
    "city": "Mangaluru",
    "state": "Karnataka",
    "languages": [
      "Kannada",
      "English",
      "Hindi"
    ],
    "availability": "today",
    "profile_photo_path": "Riya Chatterjee.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-88",
    "legacy_id": 88,
    "linked_user_id": "lawyer-user-88",
    "test_route_user_id": "lawyer-user-88",
    "display_name": "Adv. Sudhir Kadam",
    "gender": "Male",
    "legal_category": "consumer",
    "years_experience": 9,
    "seed_rating": 4.6,
    "seed_review_count": 41,
    "consultation_fee": 700,
    "locality": "Tarabai Park",
    "city": "Kolhapur",
    "state": "Maharashtra",
    "languages": [
      "Marathi",
      "Hindi",
      "English"
    ],
    "availability": "week",
    "profile_photo_path": "Swati Kulkarni.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-89",
    "legacy_id": 89,
    "linked_user_id": "lawyer-user-89",
    "test_route_user_id": "lawyer-user-89",
    "display_name": "Adv. Deepa Nair",
    "gender": "Female",
    "legal_category": "intellectual_property",
    "years_experience": 14,
    "seed_rating": 4.9,
    "seed_review_count": 76,
    "consultation_fee": 1,
    "locality": "Vellayambalam",
    "city": "Thiruvananthapuram",
    "state": "Kerala",
    "languages": [
      "Malayalam",
      "English",
      "Hindi"
    ],
    "availability": "today",
    "profile_photo_path": "Deepa Nair.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-90",
    "legacy_id": 90,
    "linked_user_id": "lawyer-user-90",
    "test_route_user_id": "lawyer-user-90",
    "display_name": "Adv. Neha Kapoor",
    "gender": "Female",
    "legal_category": "intellectual_property",
    "years_experience": 12,
    "seed_rating": 4.8,
    "seed_review_count": 64,
    "consultation_fee": 1300,
    "locality": "Sector 18",
    "city": "Noida",
    "state": "Uttar Pradesh",
    "languages": [
      "Hindi",
      "English"
    ],
    "availability": "tomorrow",
    "profile_photo_path": "Neha Kapoor.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-91",
    "legacy_id": 91,
    "linked_user_id": "lawyer-user-91",
    "test_route_user_id": "lawyer-user-91",
    "display_name": "Adv. Sameer Khan",
    "gender": "Male",
    "legal_category": "intellectual_property",
    "years_experience": 14,
    "seed_rating": 4.9,
    "seed_review_count": 71,
    "consultation_fee": 1500,
    "locality": "Mahanagar",
    "city": "Lucknow",
    "state": "Uttar Pradesh",
    "languages": [
      "Hindi",
      "Urdu",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Sameer Khan.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-92",
    "legacy_id": 92,
    "linked_user_id": "lawyer-user-92",
    "test_route_user_id": "lawyer-user-92",
    "display_name": "Adv. Priyanka Roy",
    "gender": "Female",
    "legal_category": "intellectual_property",
    "years_experience": 13,
    "seed_rating": 4.9,
    "seed_review_count": 79,
    "consultation_fee": 1400,
    "locality": "HSR Layout",
    "city": "Bengaluru",
    "state": "Karnataka",
    "languages": [
      "Bengali",
      "English",
      "Hindi"
    ],
    "availability": "today",
    "profile_photo_path": "Meera Reddy.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-93",
    "legacy_id": 93,
    "linked_user_id": "lawyer-user-93",
    "test_route_user_id": "lawyer-user-93",
    "display_name": "Adv. Devendra Rathore",
    "gender": "Male",
    "legal_category": "intellectual_property",
    "years_experience": 15,
    "seed_rating": 4.9,
    "seed_review_count": 85,
    "consultation_fee": 1600,
    "locality": "Golf Course Road",
    "city": "Gurugram",
    "state": "Haryana",
    "languages": [
      "Hindi",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Naveen Gowda.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-94",
    "legacy_id": 94,
    "linked_user_id": "lawyer-user-94",
    "test_route_user_id": "lawyer-user-94",
    "display_name": "Adv. Aparna Nambiar",
    "gender": "Female",
    "legal_category": "intellectual_property",
    "years_experience": 13,
    "seed_rating": 4.8,
    "seed_review_count": 71,
    "consultation_fee": 1450,
    "locality": "Madhapur",
    "city": "Hyderabad",
    "state": "Telangana",
    "languages": [
      "Malayalam",
      "Telugu",
      "English"
    ],
    "availability": "tomorrow",
    "profile_photo_path": "Siddharth Rao.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-95",
    "legacy_id": 95,
    "linked_user_id": "lawyer-user-95",
    "test_route_user_id": "lawyer-user-95",
    "display_name": "Adv. Chirag Somani",
    "gender": "Male",
    "legal_category": "intellectual_property",
    "years_experience": 12,
    "seed_rating": 4.8,
    "seed_review_count": 66,
    "consultation_fee": 1350,
    "locality": "Andheri East",
    "city": "Mumbai",
    "state": "Maharashtra",
    "languages": [
      "Gujarati",
      "Hindi",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Dev Patel.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-96",
    "legacy_id": 96,
    "linked_user_id": "lawyer-user-96",
    "test_route_user_id": "lawyer-user-96",
    "display_name": "Adv. Jayant Bhattacharya",
    "gender": "Male",
    "legal_category": "intellectual_property",
    "years_experience": 15,
    "seed_rating": 4.9,
    "seed_review_count": 80,
    "consultation_fee": 1550,
    "locality": "New Town",
    "city": "Kolkata",
    "state": "West Bengal",
    "languages": [
      "Bengali",
      "English",
      "Hindi"
    ],
    "availability": "week",
    "profile_photo_path": "Nikhil Patil.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-97",
    "legacy_id": 97,
    "linked_user_id": "lawyer-user-97",
    "test_route_user_id": "lawyer-user-97",
    "display_name": "Adv. Dev Patel",
    "gender": "Male",
    "legal_category": "environmental",
    "years_experience": 10,
    "seed_rating": 4.7,
    "seed_review_count": 44,
    "consultation_fee": 1,
    "locality": "Athwa Lines",
    "city": "Surat",
    "state": "Gujarat",
    "languages": [
      "Gujarati",
      "Hindi",
      "English"
    ],
    "availability": "tomorrow",
    "profile_photo_path": "Dev Patel.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-98",
    "legacy_id": 98,
    "linked_user_id": "lawyer-user-98",
    "test_route_user_id": "lawyer-user-98",
    "display_name": "Adv. Neha Kulkarni",
    "gender": "Female",
    "legal_category": "environmental",
    "years_experience": 11,
    "seed_rating": 4.8,
    "seed_review_count": 53,
    "consultation_fee": 950,
    "locality": "Ramdaspeth",
    "city": "Nagpur",
    "state": "Maharashtra",
    "languages": [
      "Marathi",
      "Hindi",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Neha Kulkarni.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-99",
    "legacy_id": 99,
    "linked_user_id": "lawyer-user-99",
    "test_route_user_id": "lawyer-user-99",
    "display_name": "Adv. Sana Qureshi",
    "gender": "Female",
    "legal_category": "environmental",
    "years_experience": 10,
    "seed_rating": 4.8,
    "seed_review_count": 49,
    "consultation_fee": 900,
    "locality": "Jubilee Hills",
    "city": "Hyderabad",
    "state": "Telangana",
    "languages": [
      "Telugu",
      "Urdu",
      "English"
    ],
    "availability": "tomorrow",
    "profile_photo_path": "Sana Qureshi.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-100",
    "legacy_id": 100,
    "linked_user_id": "lawyer-user-100",
    "test_route_user_id": "lawyer-user-100",
    "display_name": "Adv. Akhil Bharadwaj",
    "gender": "Male",
    "legal_category": "environmental",
    "years_experience": 12,
    "seed_rating": 4.8,
    "seed_review_count": 59,
    "consultation_fee": 1000,
    "locality": "Rajpur Road",
    "city": "Dehradun",
    "state": "Uttarakhand",
    "languages": [
      "Hindi",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Tanvi Shah.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-101",
    "legacy_id": 101,
    "linked_user_id": "lawyer-user-101",
    "test_route_user_id": "lawyer-user-101",
    "display_name": "Adv. Sujata Mohanty",
    "gender": "Female",
    "legal_category": "environmental",
    "years_experience": 13,
    "seed_rating": 4.8,
    "seed_review_count": 67,
    "consultation_fee": 1100,
    "locality": "Chandrasekharpur",
    "city": "Bhubaneswar",
    "state": "Odisha",
    "languages": [
      "Odia",
      "Hindi",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Sana Qureshi.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-102",
    "legacy_id": 102,
    "linked_user_id": "lawyer-user-102",
    "test_route_user_id": "lawyer-user-102",
    "display_name": "Adv. Tarun Goswami",
    "gender": "Male",
    "legal_category": "environmental",
    "years_experience": 11,
    "seed_rating": 4.7,
    "seed_review_count": 51,
    "consultation_fee": 950,
    "locality": "GS Road",
    "city": "Guwahati",
    "state": "Assam",
    "languages": [
      "Assamese",
      "Hindi",
      "English"
    ],
    "availability": "tomorrow",
    "profile_photo_path": "Ananya Rao.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-103",
    "legacy_id": 103,
    "linked_user_id": "lawyer-user-103",
    "test_route_user_id": "lawyer-user-103",
    "display_name": "Adv. Vinay Deshmukh",
    "gender": "Male",
    "legal_category": "environmental",
    "years_experience": 12,
    "seed_rating": 4.8,
    "seed_review_count": 62,
    "consultation_fee": 1050,
    "locality": "Mall Road",
    "city": "Shimla",
    "state": "Himachal Pradesh",
    "languages": [
      "Hindi",
      "English"
    ],
    "availability": "today",
    "profile_photo_path": "Arjun Mehta.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  },
  {
    "id": "lawyer-104",
    "legacy_id": 104,
    "linked_user_id": "lawyer-user-104",
    "test_route_user_id": "lawyer-user-104",
    "display_name": "Adv. Leela Krishnan",
    "gender": "Female",
    "legal_category": "environmental",
    "years_experience": 14,
    "seed_rating": 4.9,
    "seed_review_count": 74,
    "consultation_fee": 1150,
    "locality": "Adyar",
    "city": "Chennai",
    "state": "Tamil Nadu",
    "languages": [
      "Tamil",
      "English",
      "Hindi"
    ],
    "availability": "week",
    "profile_photo_path": "Anjali Rao.jpg",
    "source": "directory",
    "is_active": true,
    "is_bookable": true,
    "is_test_bookable": true
  }
];

// Pre-seeded Users and Profiles
const INITIAL_USERS = [
  {
    id: "client-user-default",
    email: "client@nyayasetu.com",
    role: "client",
    full_name: "Rahul Sharma",
    phone: "9876543210",
    city: "Pune",
    state: "Maharashtra",
    is_active: true,
    email_confirmed_at: "2025-01-01T00:00:00.000Z"
  },
  ...INITIAL_LAWYERS.map((l, idx) => ({
    id: l.linked_user_id || ("lawyer-user-" + (idx + 1)),
    email: l.id === "lawyer-1" ? "abhisheksarangale@gmail.com" : (l.id + "@nyayasetu.com"),
    secondary_email: l.id + "@nyayasetu.com",
    role: "lawyer",
    full_name: l.display_name,
    phone: "98" + String(10000000 + idx + 1).slice(-8),
    city: l.city,
    state: l.state,
    is_active: true,
    email_confirmed_at: "2025-01-01T00:00:00.000Z",
    lawyer_profile: {
      user_id: l.linked_user_id || ("lawyer-user-" + (idx + 1)),
      display_name: l.display_name,
      legal_category: l.legal_category,
      years_experience: l.years_experience,
      languages: l.languages,
      consultation_fee: l.consultation_fee,
      city: l.city,
      state: l.state,
      profile_photo_path: l.profile_photo_path,
      approval_status: "APPROVED",
      rejection_reason: null,
      approved_at: "2025-01-01T00:00:00.000Z",
      rejected_at: null,
      is_active: true
    }
  }))
];

const CATEGORY_PRACTICE_AREAS: Record<string, string[]> = {
  criminal: ["Criminal Defense", "Bail & Anticipatory Bail", "White Collar Crimes", "Trial & Appellate Advocacy"],
  family: ["Family Law", "Matrimonial Disputes", "Divorce & Child Custody", "Domestic Violence & Maintenance"],
  property: ["Property Disputes", "Civil Litigation", "Title Due Diligence", "RERA Litigation"],
  corporate: ["Corporate Governance", "Commercial Contracts", "M&A & Joint Ventures", "Regulatory Compliance"],
  civil: ["Civil Litigation", "Property & Land Disputes", "Contract Enforcement", "Recovery & Injunction Suits"],
  financial: ["Banking & Debt Recovery", "Insolvency & Bankruptcy (IBC)", "Cheque Bounce (Sec 138)", "Financial Arbitration"],
  cyber: ["Cyber Crime & Fraud", "Online Financial Disputes", "Data Protection & Privacy", "IT Act Compliance"],
  labour: ["Labour & Employment Law", "Industrial Disputes", "Employment Contracts & Benefits", "POSH Compliance"],
  taxation: ["Taxation & GST", "Income Tax Appeals", "Financial Disputes", "Corporate Tax Audits"],
  constitutional: ["Constitutional Law", "Supreme Court Appeals", "High Court Writ Petitions", "Public Interest Litigation (PIL)"],
  consumer: ["Consumer Protection", "Product Liability", "Deficiency of Service", "National Consumer Commission Disputes"],
  intellectual_property: ["Intellectual Property Law", "Trademarks & Copyrights", "Patent Prosecution", "Brand & Licensing Agreements"],
  environmental: ["Environmental Law", "National Green Tribunal (NGT)", "Pollution Control Compliance", "Forest & Wildlife Clearances"]
};

// Seed lawyer profiles for all 104 lawyers
const INITIAL_LAWYER_PROFILES = INITIAL_LAWYERS.map((lawyer) => ({
  id: lawyer.linked_user_id || lawyer.id,
  user_id: lawyer.linked_user_id || lawyer.id,
  display_name: lawyer.display_name,
  legal_category: lawyer.legal_category,
  practice_areas: CATEGORY_PRACTICE_AREAS[lawyer.legal_category] || [lawyer.legal_category],
  years_experience: lawyer.years_experience,
  languages: lawyer.languages,
  consultation_fee: lawyer.consultation_fee,
  city: lawyer.city,
  state: lawyer.state,
  profile_photo_path: lawyer.profile_photo_path,
  approval_status: "APPROVED",
  rejection_reason: null,
  approved_at: "2025-01-01T00:00:00.000Z",
  rejected_at: null,
  is_active: true
}));

// In-Memory Database collections
const db = {
  profiles: [...INITIAL_USERS.map(u => ({
    id: u.id,
    role: u.role,
    full_name: u.full_name,
    phone: u.phone || null,
    city: u.city || null,
    state: u.state || null,
    is_active: u.is_active !== false
  }))],
  users: [...INITIAL_USERS],
  lawyer_directory_profiles: [...INITIAL_LAWYERS],
  lawyer_profiles: [...INITIAL_LAWYER_PROFILES],
  appointments: [] as any[],
  payments: [] as any[],
  receipts: [] as any[],
  payouts: [] as any[],
  refunds: [] as any[],
  lawyer_approval_history: [] as any[],
  appointment_documents: [] as any[],
  notifications: [] as any[],
  reviews: [] as any[],
  lawyer_verification_details: [] as any[]
};

// =========================================================
// HELPER FILTER FUNCTION (PostgREST format parser)
// =========================================================
function filterRecords(records: any[], query: Record<string, any>) {
  let result = [...records];

  for (const [key, rawVal] of Object.entries(query)) {
    if (["select", "order", "limit", "offset", "columns"].includes(key)) {
      continue;
    }

    const val = String(rawVal);

    if (val.startsWith("eq.")) {
      const target = val.slice(3);
      result = result.filter(r => {
        const itemVal = r[key];
        if (target === "true") return itemVal === true;
        if (target === "false") return itemVal === false;
        if (target === "null") return itemVal === null || itemVal === undefined;
        return String(itemVal ?? "") === target;
      });
    } else if (val.startsWith("neq.")) {
      const target = val.slice(4);
      result = result.filter(r => String(r[key] ?? "") !== target);
    } else if (val.startsWith("is.")) {
      const target = val.slice(3);
      if (target === "null") {
        result = result.filter(r => r[key] === null || r[key] === undefined);
      }
    } else if (val.startsWith("in.")) {
      const targetList = val.slice(3).replace(/^\(|\)$/g, "").split(",").map(s => s.trim());
      result = result.filter(r => targetList.includes(String(r[key])));
    } else if (val.startsWith("ilike.")) {
      const pattern = val.slice(6).replace(/%/g, ".*");
      const re = new RegExp(pattern, "i");
      result = result.filter(r => re.test(String(r[key] ?? "")));
    }
  }

  // Handle Order
  if (query.order) {
    const [orderCol, orderDir] = String(query.order).split(".");
    result.sort((a, b) => {
      const valA = a[orderCol];
      const valB = b[orderCol];
      if (typeof valA === "number" && typeof valB === "number") {
        return orderDir === "desc" ? valB - valA : valA - valB;
      }
      return orderDir === "desc"
        ? String(valB ?? "").localeCompare(String(valA ?? ""))
        : String(valA ?? "").localeCompare(String(valB ?? ""));
    });
  }

  // Handle Limit & Offset
  if (query.offset) {
    const offset = parseInt(String(query.offset), 10);
    if (!isNaN(offset)) result = result.slice(offset);
  }
  if (query.limit) {
    const limit = parseInt(String(query.limit), 10);
    if (!isNaN(limit)) result = result.slice(0, limit);
  }

  return result;
}

// =========================================================
// SUPABASE AUTH ENDPOINTS (/auth/v1/*)
// =========================================================

app.post("/auth/v1/token", (req, res) => {
  const { email, password } = req.body || {};
  const cleanEmail = String(email || "").trim().toLowerCase();

  if (!cleanEmail) {
    return res.status(400).json({ error: "invalid_grant", error_description: "Invalid login credentials" });
  }

  // Find user by email (or default role accounts)
  let user = db.users.find(u =>
    u.email?.toLowerCase() === cleanEmail ||
    (u as any).secondary_email?.toLowerCase() === cleanEmail
  );

  // If user doesn't exist, allow auto-creation or graceful role match
  if (!user) {
    let assignedRole = "client";
    let fullName = cleanEmail.split("@")[0].replace(/[._-]/g, " ");
    fullName = fullName.charAt(0).toUpperCase() + fullName.slice(1);

    if (cleanEmail.includes("lawyer")) {
      assignedRole = "lawyer";
      fullName = "Adv. " + fullName;
    }

    const newId = "user-" + Math.random().toString(36).substring(2, 10);
    user = {
      id: newId,
      email: cleanEmail,
      role: assignedRole,
      full_name: fullName,
      phone: "9876543210",
      city: "Mumbai",
      state: "Maharashtra",
      is_active: true,
      email_confirmed_at: new Date().toISOString()
    };
    db.users.push(user);
    db.profiles.push({
      id: newId,
      role: assignedRole,
      full_name: fullName,
      phone: "9876543210",
      city: "Mumbai",
      state: "Maharashtra",
      is_active: true
    });

    if (assignedRole === "lawyer") {
      db.lawyer_profiles.push({
        user_id: newId,
        display_name: fullName,
        legal_category: "criminal",
        years_experience: 8,
        languages: ["English", "Hindi"],
        consultation_fee: 1,
        city: "Mumbai",
        state: "Maharashtra",
        profile_photo_path: "Abhishek Sarangale.jpg",
        approval_status: "APPROVED",
        rejection_reason: null,
        approved_at: new Date().toISOString(),
        rejected_at: null,
        is_active: true
      });
    }
  }

  const tokenPayload = {
    access_token: "token_" + user.id + "_" + Date.now(),
    token_type: "bearer",
    expires_in: 604800,
    refresh_token: "refresh_" + user.id + "_" + Date.now(),
    user: {
      id: user.id,
      aud: "authenticated",
      role: "authenticated",
      email: user.email,
      email_confirmed_at: user.email_confirmed_at || new Date().toISOString(),
      phone: user.phone || "",
      app_metadata: { provider: "email", providers: ["email"] },
      user_metadata: {
        full_name: user.full_name,
        role: user.role
      },
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    }
  };

  return res.status(200).json(tokenPayload);
});

app.post("/auth/v1/signup", (req, res) => {
  const { email, password, data } = req.body || {};
  const cleanEmail = String(email || "").trim().toLowerCase();
  const role = data?.role || "client";
  const fullName = data?.full_name || cleanEmail.split("@")[0];

  const newId = "user-" + Math.random().toString(36).substring(2, 10);
  const newUser = {
    id: newId,
    email: cleanEmail,
    role,
    full_name: fullName,
    phone: data?.phone || "",
    city: data?.city || "",
    state: data?.state || "",
    is_active: true,
    email_confirmed_at: new Date().toISOString()
  };

  db.users.push(newUser);
  db.profiles.push({
    id: newId,
    role,
    full_name: fullName,
    phone: data?.phone || null,
    city: data?.city || null,
    state: data?.state || null,
    is_active: true
  });

  return res.status(200).json({
    id: newId,
    email: cleanEmail,
    user: {
      id: newId,
      email: cleanEmail,
      email_confirmed_at: new Date().toISOString(),
      user_metadata: { full_name: fullName, role }
    }
  });
});

app.get("/auth/v1/user", (req, res) => {
  const authHeader = req.headers.authorization || "";
  const token = authHeader.replace(/^Bearer\s+/i, "").trim();

  let user = db.users[0];
  if (token && token.startsWith("token_")) {
    const parts = token.split("_");
    const userId = parts[1];
    const found = db.users.find(u => u.id === userId);
    if (found) user = found;
  }

  return res.status(200).json({
    id: user.id,
    aud: "authenticated",
    role: "authenticated",
    email: user.email,
    email_confirmed_at: user.email_confirmed_at || new Date().toISOString(),
    user_metadata: { full_name: user.full_name, role: user.role }
  });
});

app.post("/auth/v1/logout", (req, res) => {
  return res.status(200).json({ message: "Logged out successfully" });
});

app.post("/auth/v1/resend", (req, res) => {
  return res.status(200).json({ message: "Verification email resent" });
});

// =========================================================
// SUPABASE POSTGREST REST ENDPOINTS (/rest/v1/:table)
// =========================================================

app.get("/rest/v1/:table", (req, res) => {
  const table = req.params.table as keyof typeof db;
  if (!db[table]) {
    return res.status(200).json([]);
  }

  const results = filterRecords(db[table], req.query);

  // If header requests single object (PostgREST)
  const acceptHeader = req.headers.accept || "";
  if (acceptHeader.includes("vnd.pgrst.object+json")) {
    if (results.length === 0) {
      return res.status(406).json({ code: "PGRST116", details: "The result contains 0 rows", message: "JSON object requested, multiple (or no) rows returned" });
    }
    return res.status(200).json(results[0]);
  }

  return res.status(200).json(results);
});

// PostgREST RPC function handler
app.post("/rest/v1/rpc/:fn", (req, res) => {
  const fn = req.params.fn;
  if (fn === "submit_payment_for_verification") {
    const { p_appointment_id, p_upi_transaction_id } = req.body || {};
    let apt = db.appointments.find((a: any) => a.id === p_appointment_id);
    if (!apt) {
      apt = {
        id: p_appointment_id || "apt-" + Math.random().toString(36).substring(2, 10),
        client_id: "client-user-default",
        lawyer_id: "lawyer-user-1",
        consultation_fee: 1,
        status: "PAYMENT_PENDING",
        created_at: new Date().toISOString()
      };
      db.appointments.push(apt);
    }
    apt.status = "CONFIRMED";
    const amount = Number(apt.consultation_fee || 1);
    const platform_fee = Number((amount * 0.10).toFixed(2));
    const lawyer_share = Number((amount * 0.90).toFixed(2));

    const paymentRecord = {
      id: "pay-" + Math.random().toString(36).substring(2, 10),
      appointment_id: apt.id,
      client_id: apt.client_id,
      lawyer_id: apt.lawyer_id,
      upi_transaction_id: p_upi_transaction_id || "UPI" + Date.now(),
      amount: amount,
      platform_fee: platform_fee,
      lawyer_share: lawyer_share,
      status: "PAYMENT_VERIFIED",
      payment_status: "PAYMENT_VERIFIED",
      verified_at: new Date().toISOString(),
      created_at: new Date().toISOString()
    };
    db.payments.push(paymentRecord);
    broadcastRealtimeChange("payments", "INSERT", paymentRecord);
    broadcastRealtimeChange("appointments", "UPDATE", apt);

    return res.status(200).json(paymentRecord);
  }
  return res.status(200).json({ success: true });
});

app.post("/rest/v1/:table", (req, res) => {
  const table = req.params.table as keyof typeof db;
  if (!db[table]) {
    db[table] = [] as any;
  }

  const body = req.body;
  const items = Array.isArray(body) ? body : [body];
  const inserted: any[] = [];

  for (const item of items) {
    const record = {
      id: item.id || "rec-" + Math.random().toString(36).substring(2, 10),
      created_at: item.created_at || new Date().toISOString(),
      ...item
    };
    (db[table] as any[]).push(record);
    inserted.push(record);
    broadcastRealtimeChange(table as string, "INSERT", record);
  }

  const prefer = req.headers.prefer || "";
  if (String(prefer).includes("return=representation")) {
    return res.status(201).json(Array.isArray(body) ? inserted : inserted[0]);
  }

  return res.status(201).json(inserted);
});

app.patch("/rest/v1/:table", (req, res) => {
  const table = req.params.table as keyof typeof db;
  if (!db[table]) {
    return res.status(200).json([]);
  }

  const matches = filterRecords(db[table], req.query);
  const patchData = req.body || {};

  matches.forEach(m => {
    Object.assign(m, patchData, { updated_at: new Date().toISOString() });
    broadcastRealtimeChange(table as string, "UPDATE", m);
  });

  return res.status(200).json(matches);
});

app.put("/rest/v1/:table", (req, res) => {
  const table = req.params.table as keyof typeof db;
  if (!db[table]) {
    db[table] = [] as any;
  }

  const item = req.body || {};
  const idKey = item.id ? "id" : (item.user_id ? "user_id" : (item.lawyer_id ? "lawyer_id" : "id"));
  const existingIdx = (db[table] as any[]).findIndex(r => r[idKey] === item[idKey]);

  let updatedRecord;
  if (existingIdx >= 0) {
    (db[table] as any[])[existingIdx] = { ...(db[table] as any[])[existingIdx], ...item };
    updatedRecord = (db[table] as any[])[existingIdx];
    broadcastRealtimeChange(table as string, "UPDATE", updatedRecord);
  } else {
    updatedRecord = {
      id: item.id || "rec-" + Math.random().toString(36).substring(2, 10),
      created_at: new Date().toISOString(),
      ...item
    };
    (db[table] as any[]).push(updatedRecord);
    broadcastRealtimeChange(table as string, "INSERT", updatedRecord);
  }

  return res.status(200).json(item);
});

app.delete("/rest/v1/:table", (req, res) => {
  const table = req.params.table as keyof typeof db;
  if (!db[table]) {
    return res.status(200).json([]);
  }

  const matches = filterRecords(db[table], req.query);
  const matchIds = new Set(matches.map(m => m.id || m.user_id));

  db[table] = (db[table] as any[]).filter(r => !matchIds.has(r.id || r.user_id));
  matches.forEach(m => {
    broadcastRealtimeChange(table as string, "DELETE", m);
  });

  return res.status(200).json(matches);
});

// =========================================================
// STORAGE ENDPOINTS
// =========================================================

app.get("/storage/v1/object/public/lawyer-profile-photos/:photo", (req, res) => {
  const photoName = decodeURIComponent(req.params.photo);
  const photoPath = path.resolve(process.cwd(), "Frontend/images/lawyers", photoName);

  if (fs.existsSync(photoPath)) {
    return res.sendFile(photoPath);
  }
  // Fallback to default lawyer photo
  const defaultPhoto = path.resolve(process.cwd(), "Frontend/images/lawyers/Aarti More.jpg");
  if (fs.existsSync(defaultPhoto)) {
    return res.sendFile(defaultPhoto);
  }
  return res.status(404).send("Image not found");
});

// =========================================================
// BACKEND CUSTOM REGISTRATION & PDF APIS
// =========================================================

app.get("/api/health", (req, res) => {
  return res.json({
    success: true,
    service: "NyayaSetu Full-Stack Backend",
    status: "running",
    lawyersCount: db.lawyer_directory_profiles.length,
    usersCount: db.users.length
  });
});

app.get("/api/lawyers", (req, res) => {
  return res.json(db.lawyer_directory_profiles);
});

app.get("/api/lawyer-profiles", (req, res) => {
  return res.json(db.lawyer_profiles);
});

app.post("/api/register/client", (req, res) => {
  try {
    const { fullName, email, password, phone, city, state } = req.body || {};
    const cleanEmail = String(email || "").trim().toLowerCase();

    if (!cleanEmail || !password) {
      return res.status(400).json({ success: false, message: "Email and password are required." });
    }

    const newId = "user-" + Math.random().toString(36).substring(2, 10);
    const newUser = {
      id: newId,
      email: cleanEmail,
      role: "client",
      full_name: fullName || cleanEmail.split("@")[0],
      phone: phone || null,
      city: city || null,
      state: state || null,
      is_active: true,
      email_confirmed_at: new Date().toISOString()
    };

    db.users.push(newUser);
    db.profiles.push({
      id: newId,
      role: "client",
      full_name: fullName || cleanEmail.split("@")[0],
      phone: phone || null,
      city: city || null,
      state: state || null,
      is_active: true
    });

    return res.status(201).json({
      success: true,
      message: "Client account created successfully. You can now log in."
    });
  } catch (err: any) {
    return res.status(500).json({ success: false, message: err.message || "Registration failed." });
  }
});

app.post("/api/register/lawyer", (req, res) => {
  try {
    const { fullName, email, password, phone, city, state, legalCategory, yearsExperience, languages, consultationFee } = req.body || {};
    const cleanEmail = String(email || "").trim().toLowerCase();

    const newId = "user-" + Math.random().toString(36).substring(2, 10);
    const newUser = {
      id: newId,
      email: cleanEmail,
      role: "lawyer",
      full_name: fullName || "Advocate",
      phone: phone || null,
      city: city || null,
      state: state || null,
      is_active: true,
      email_confirmed_at: new Date().toISOString()
    };

    db.users.push(newUser);
    db.profiles.push({
      id: newId,
      role: "lawyer",
      full_name: fullName,
      phone: phone || null,
      city: city || null,
      state: state || null,
      is_active: true
    });

    db.lawyer_profiles.push({
      user_id: newId,
      display_name: fullName,
      legal_category: legalCategory || "civil",
      years_experience: Number(yearsExperience) || 5,
      languages: Array.isArray(languages) ? languages : [languages || "English", "Hindi"],
      consultation_fee: Number(consultationFee) || 1,
      city: city || "Mumbai",
      state: state || "Maharashtra",
      profile_photo_path: "Abhishek Sarangale.jpg",
      approval_status: "PENDING",
      rejection_reason: null,
      approved_at: null,
      rejected_at: null,
      is_active: true
    });

    return res.status(201).json({
      success: true,
      message: "Lawyer registration submitted successfully. Your profile is pending Admin approval."
    });
  } catch (err: any) {
    return res.status(500).json({ success: false, message: err.message || "Registration failed." });
  }
});

app.post("/api/admin/payments/:paymentId/generate-receipt-pdf", (req, res) => {
  return res.status(200).json({
    success: true,
    message: "Receipt PDF generated successfully.",
    receipt: {
      paymentId: req.params.paymentId,
      receiptNumber: "NYA-" + Date.now(),
      generatedAt: new Date().toISOString()
    }
  });
});

// =========================================================
// NYAYASETU DURABLE STORAGE SERVICE
// =========================================================

const UPLOAD_ROOT = path.resolve(process.cwd(), "public", "uploads");
if (!fs.existsSync(UPLOAD_ROOT)) {
  fs.mkdirSync(UPLOAD_ROOT, { recursive: true });
}

function getContentType(filename: string): string {
  const ext = path.extname(filename).toLowerCase();
  switch (ext) {
    case ".pdf": return "application/pdf";
    case ".png": return "image/png";
    case ".jpg":
    case ".jpeg": return "image/jpeg";
    case ".webp": return "image/webp";
    case ".doc": return "application/msword";
    case ".docx": return "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
    case ".txt": return "text/plain";
    default: return "application/octet-stream";
  }
}

app.post("/api/storage/upload", (req, res) => {
  try {
    const { bucket = "appointment-documents", path: relPath, fileName, fileType, fileData } = req.body;
    if (!relPath || !fileData) {
      return res.status(400).json({ success: false, error: "Missing required path or fileData" });
    }

    const safeRelPath = relPath.replace(/\.\./g, "").replace(/^\/+/, "");
    const safeBucket = (bucket || "appointment-documents").replace(/[^a-zA-Z0-9_-]/g, "");
    const targetFile = path.join(UPLOAD_ROOT, safeBucket, safeRelPath);
    const targetDir = path.dirname(targetFile);

    if (!fs.existsSync(targetDir)) {
      fs.mkdirSync(targetDir, { recursive: true });
    }

    const fileBuffer = Buffer.from(fileData, "base64");
    fs.writeFileSync(targetFile, fileBuffer);

    console.log(`[Storage] File saved successfully: ${safeBucket}/${safeRelPath} (${fileBuffer.length} bytes)`);

    // Synchronize to appointment_documents database record
    const parts = safeRelPath.split("/");
    const appointmentId = parts.length > 1 ? parts[0] : null;
    if (appointmentId) {
      if (!db["appointment_documents" as keyof typeof db]) {
        (db as any)["appointment_documents"] = [];
      }
      const docRecord = {
        id: "doc-" + Math.random().toString(36).substring(2, 10),
        appointment_id: appointmentId,
        file_name: fileName || path.basename(safeRelPath),
        file_path: safeRelPath,
        file_size_bytes: fileBuffer.length,
        file_type: fileType || getContentType(safeRelPath),
        created_at: new Date().toISOString()
      };
      (db as any)["appointment_documents"].push(docRecord);
      broadcastRealtimeChange("appointment_documents", "INSERT", docRecord);
    }

    return res.status(200).json({
      success: true,
      data: {
        path: safeRelPath,
        Key: safeRelPath,
        fullPath: `${safeBucket}/${safeRelPath}`,
        size: fileBuffer.length
      },
      error: null
    });
  } catch (err: any) {
    console.error("[Storage] Upload error:", err);
    return res.status(500).json({ success: false, error: err.message || "File upload failed" });
  }
});

// Storage Sign endpoint (compatible with Supabase Storage createSignedUrl)
app.post("/storage/v1/object/sign/:bucket/*", (req, res) => {
  const bucket = req.params.bucket;
  const relPath = req.params[0];
  return res.status(200).json({
    signedURL: `/storage/v1/object/${bucket}/${relPath}`
  });
});

// Supabase direct upload fallback
app.put("/storage/v1/object/:bucket/*", express.raw({ type: "*/*", limit: "25mb" }), (req, res) => {
  try {
    const bucket = (req.params.bucket || "appointment-documents").replace(/[^a-zA-Z0-9_-]/g, "");
    const relPath = (req.params[0] || "").replace(/\.\./g, "").replace(/^\/+/, "");
    const targetFile = path.join(UPLOAD_ROOT, bucket, relPath);
    const targetDir = path.dirname(targetFile);

    if (!fs.existsSync(targetDir)) {
      fs.mkdirSync(targetDir, { recursive: true });
    }

    if (Buffer.isBuffer(req.body)) {
      fs.writeFileSync(targetFile, req.body);
    } else if (typeof req.body === "string") {
      fs.writeFileSync(targetFile, Buffer.from(req.body));
    }

    return res.status(200).json({
      Key: `${bucket}/${relPath}`,
      message: "Uploaded successfully"
    });
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

// Storage Object Serving (PDF, images, documents inline)
const serveStorageObject = (req: express.Request, res: express.Response) => {
  try {
    const bucket = (req.params.bucket || "appointment-documents").replace(/[^a-zA-Z0-9_-]/g, "");
    const relPath = (req.params[0] || "").replace(/\.\./g, "").replace(/^\/+/, "");
    const filePath = path.join(UPLOAD_ROOT, bucket, relPath);

    if (!fs.existsSync(filePath) || !fs.statSync(filePath).isFile()) {
      return res.status(404).json({
        statusCode: "404",
        error: "Not Found",
        message: "The resource was not found"
      });
    }

    const contentType = getContentType(filePath);
    const fileName = path.basename(filePath);

    res.setHeader("Content-Type", contentType);
    res.setHeader("Content-Disposition", `inline; filename="${encodeURIComponent(fileName)}"`);
    res.setHeader("Cache-Control", "public, max-age=3600");
    res.setHeader("Access-Control-Allow-Origin", "*");

    const readStream = fs.createReadStream(filePath);
    return readStream.pipe(res);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
};

app.get("/storage/v1/object/public/:bucket/*", serveStorageObject);
app.get("/storage/v1/object/sign/:bucket/*", serveStorageObject);
app.get("/storage/v1/object/:bucket/*", serveStorageObject);
app.get("/api/storage/:bucket/*", serveStorageObject);

// =========================================================
// REALTIME WEBSOCKET SERVER (PHOENIX CHANNEL COMPATIBLE)
// =========================================================

interface ConnectedClient {
  ws: WebSocket;
  subscribedTopics: Set<string>;
  isArrayProtocol: boolean;
}

const connectedClients = new Set<ConnectedClient>();

export function broadcastRealtimeChange(table: string, eventType: string = "INSERT", record: any = {}) {
  const commitTimestamp = new Date().toISOString();
  const payloadData = {
    schema: "public",
    table: table,
    commit_timestamp: commitTimestamp,
    eventType: eventType,
    new: record,
    old: eventType === "DELETE" ? record : {}
  };

  const payload = {
    data: payloadData,
    ids: []
  };

  for (const client of connectedClients) {
    if (client.ws.readyState === WebSocket.OPEN) {
      for (const topic of client.subscribedTopics) {
        try {
          if (client.isArrayProtocol) {
            client.ws.send(JSON.stringify([null, null, topic, "postgres_changes", payload]));
          } else {
            client.ws.send(JSON.stringify({
              join_ref: null,
              ref: null,
              topic: topic,
              event: "postgres_changes",
              payload: payload
            }));
          }
        } catch (e) {
          // ignore send error
        }
      }
    }
  }
}

const wss = new WebSocketServer({ server, path: "/realtime/v1/websocket" });

wss.on("connection", (ws) => {
  const client: ConnectedClient = {
    ws,
    subscribedTopics: new Set<string>(),
    isArrayProtocol: true
  };
  connectedClients.add(client);

  ws.on("message", (messageData) => {
    try {
      const text = messageData.toString();
      if (!text) return;

      if (text.startsWith("[")) {
        client.isArrayProtocol = true;
        const [joinRef, ref, topic, event, payload] = JSON.parse(text);

        if (event === "phx_join") {
          client.subscribedTopics.add(topic);
          const reply = [
            joinRef,
            ref,
            topic,
            "phx_reply",
            {
              status: "ok",
              response: { postgres_changes: [] }
            }
          ];
          ws.send(JSON.stringify(reply));
        } else if (event === "heartbeat") {
          const reply = [
            null,
            ref,
            "phoenix",
            "phx_reply",
            {
              status: "ok",
              response: {}
            }
          ];
          ws.send(JSON.stringify(reply));
        } else if (event === "access_token") {
          const reply = [
            joinRef,
            ref,
            topic,
            "phx_reply",
            {
              status: "ok",
              response: {}
            }
          ];
          ws.send(JSON.stringify(reply));
        } else if (event === "phx_leave") {
          client.subscribedTopics.delete(topic);
          const reply = [
            joinRef,
            ref,
            topic,
            "phx_reply",
            {
              status: "ok",
              response: {}
            }
          ];
          ws.send(JSON.stringify(reply));
        }
      } else if (text.startsWith("{")) {
        client.isArrayProtocol = false;
        const msg = JSON.parse(text);
        const { join_ref, ref, topic, event } = msg;

        if (event === "phx_join") {
          client.subscribedTopics.add(topic);
          ws.send(JSON.stringify({
            join_ref: join_ref,
            ref: ref,
            topic: topic,
            event: "phx_reply",
            payload: {
              status: "ok",
              response: { postgres_changes: [] }
            }
          }));
        } else if (event === "heartbeat") {
          ws.send(JSON.stringify({
            join_ref: null,
            ref: ref,
            topic: "phoenix",
            event: "phx_reply",
            payload: {
              status: "ok",
              response: {}
            }
          }));
        } else if (event === "access_token") {
          ws.send(JSON.stringify({
            join_ref: join_ref,
            ref: ref,
            topic: topic,
            event: "phx_reply",
            payload: {
              status: "ok",
              response: {}
            }
          }));
        } else if (event === "phx_leave") {
          client.subscribedTopics.delete(topic);
          ws.send(JSON.stringify({
            join_ref: join_ref,
            ref: ref,
            topic: topic,
            event: "phx_reply",
            payload: {
              status: "ok",
              response: {}
            }
          }));
        }
      }
    } catch (err) {
      console.warn("Realtime WebSocket message error:", err);
    }
  });

  ws.on("close", () => {
    connectedClients.delete(client);
  });

  ws.on("error", () => {
    connectedClients.delete(client);
  });
});

// =========================================================
// STATIC FILE SERVING & NAVIGATION
// =========================================================

const frontendDir = path.resolve(process.cwd(), "Frontend");
const htmlDir = path.resolve(frontendDir, "html");
const cssDir = path.resolve(frontendDir, "css");
const jsDir = path.resolve(frontendDir, "js");
const imagesDir = path.resolve(frontendDir, "images");
const iconsDir = path.resolve(frontendDir, "icons");

app.get("/", (req, res) => {
  res.redirect("/Frontend/html/index.html");
});

app.get("/index.html", (req, res) => {
  res.redirect("/Frontend/html/index.html");
});

app.use("/Frontend", express.static(frontendDir));
app.use("/html", express.static(htmlDir));
app.use("/css", express.static(cssDir));
app.use("/js", express.static(jsDir));
app.use("/images", express.static(imagesDir));
app.use("/icons", express.static(iconsDir));

app.get("/:page.html", (req, res, next) => {
  const pagePath = path.join(htmlDir, `${req.params.page}.html`);
  if (fs.existsSync(pagePath)) {
    return res.sendFile(pagePath);
  }
  next();
});

app.use(express.static(frontendDir));

server.listen(PORT, "0.0.0.0", () => {
  console.log(`============================================`);
  console.log(`NYAYASETU RUNNING ON http://localhost:${PORT}`);
  console.log(`Directory: 49 Verified Indian Lawyers Loaded`);
  console.log(`Realtime: WebSocket Server Active`);
  console.log(`============================================`);
});
