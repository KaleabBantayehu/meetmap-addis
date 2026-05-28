# MeetMap Addis

MeetMap Addis is a Flutter-based discovery platform designed to help people find trusted places, events, and hangouts in Addis Ababa for studying, meetings, work, dating, dining, and social experiences.

The project combines Firebase, Cloudinary, and Gebeta Maps to create a modern, mobile-first discovery experience focused on local relevance and practical usability.

---

## Features

### Discovery

* Browse places across Addis Ababa
* Explore events and hangouts
* Dynamic search
* Dynamic filtering
* Place detail pages
* Event detail pages
* Hangout detail pages
* Featured and category-based discovery

### Maps & Location

* Gebeta Maps integration
* Interactive map view
* Map pin selection when creating locations
* Geocoding support with fallback flow
* Route visualization
* Distance and ETA display
* Location-aware discovery

### Social & Community

* Reviews and ratings
* Saved/Favorite places
* Networking basics
* Follow system basics
* Profile viewing and interaction

### User Features

* Firebase Authentication
* Profile editing
* Profile image uploads
* Password reset flow
* User account management

### Media Uploads

* Cloudinary image uploads
* Dedicated upload flows for:

  * Places
  * Events
  * Hangouts
  * Profile images

### Backend & Data

* Firebase Firestore backend
* Offline-first caching
* Dynamic provider-driven UI
* Real-time-ready architecture foundation

---

## Tech Stack

### Frontend

* Flutter
* Dart

### Backend

* Firebase Authentication
* Cloud Firestore

### Maps

* Gebeta Maps
* Gebeta Directions API

### Media Storage

* Cloudinary

### State Management

* Provider

### Architecture

* Feature-based architecture
* Beginner-friendly structure
* Reusable widgets
* Minimal abstraction
* No unnecessary overengineering

---

## Architecture Overview

Simplified project structure:

lib/
│
├── core/
│   ├── constants/
│   ├── theme/
│   └── utils/
│
├── shared/
│   ├── models/
│   └── widgets/
│
├── features/
│   ├── auth/
│   ├── home/
│   ├── explore/
│   ├── places/
│   ├── events/
│   ├── hangouts/
│   ├── reviews/
│   ├── networking/
│   ├── profile/
│   └── settings/

The project follows a simple feature-first structure to keep development approachable while remaining scalable.

---

## Getting Started

### Requirements

Before running the project, ensure you have:

* Flutter SDK installed
* Firebase project configured
* Cloudinary account configured
* Gebeta Maps API token


## Firebase Setup

Configure Firebase for:

### Authentication

Enable:

* Email/Password authentication

### Firestore

Create Firestore database and configure security rules according to your environment.

Used collections may include:

* users
* places
* reviews
* events
* hangouts
* saved_places

---

## User Experience Flow

MeetMap Addis focuses on four main experiences:

### Discover

Find cafés, workspaces, restaurants, events, and social spaces.

### Create

Add places, events, and hangouts with images and location data.

### Navigate

Use maps and routing tools to understand where locations are and how far they are.

### Connect

Interact through reviews, saves, and networking features.

---

## MVP Philosophy

MeetMap Addis intentionally prioritizes:

* Simple architecture
* Reusable widgets
* Firebase-first backend
* Minimal complexity
* Practical scalability

The project avoids unnecessary architectural complexity and focuses on shipping a functional and maintainable MVP.

---

## Future Improvements

Potential future directions include:

* Stronger navigation experience
* Notifications
* Richer networking systems
* Moderation tools
* Enhanced recommendation systems

---

## Project Status

MeetMap Addis is currently under active MVP development.

The current focus is:

* stability
* usability
* discovery experience
* reliable backend integration
* practical local-first UX

---

Built with Flutter, Firebase, Cloudinary, and Gebeta Maps for Addis Ababa discovery.