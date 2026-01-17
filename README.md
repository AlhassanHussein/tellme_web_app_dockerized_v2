# TellMe – Anonymous Temporary Messages Web App

TellMe is a full-stack web application that allows users to receive **anonymous messages** through **temporary links**.  
Each generated session creates a **public link** to receive messages and a **private link** to view them.  
All data is automatically deleted after a selected time period (6, 12, or 24 hours).

This project is built as a **monolithic application** and is designed to be easily upgraded later to Docker and Kubernetes.

---

## ✨ Features

- Generate **temporary anonymous messaging links**
- Public link to receive anonymous messages
- Private link to view received messages
- Message sender identity is completely hidden
- Automatic expiration (6 / 12 / 24 hours)
- Countdown timer before expiration
- Auto-delete all data after expiration
- Multi-language support:
  - English
  - Arabic (RTL)
  - Spanish
- Clean, modern, responsive UI
- No authentication required

---

## 🖼️ Screenshots

### Home – Generate Links
![Home Page](screenshots/home.png)

### Public Page – Send Anonymous Message
![Public Page](screenshots/public.png)

### Private Page – Inbox
![Private Page](screenshots/private.png)

> 📌 Screenshots are located in the `screenshots/` folder.

---

## 🛠 Tech Stack

- **Backend:** Python, FastAPI
- **Frontend:** HTML, CSS, JavaScript
- **Database:** SQLite
- **Server:** Uvicorn
- **Architecture:** Monolithic (Cloud-ready)

---

## 📁 Project Structure

