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

### public – Generate Links
![public Page](screenshots/public.png)

### links – Generate Links
![links Page](screenshots/links.png)

### send messags – Generate Links
![send messags Page](screenshots/send_messags.png)

###  sent – Generate Links
![sent Page](screenshots/sent.png)

### recived messags – Generate Links
![recived messags Page](screenshots/recived_messags.png)




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
.
├── backend/
│   ├── database.py
│   ├── main.py
│   ├── models.py
│   ├── scheduler.py
│   └── routers/
│       └── api.py
├── frontend/
│   ├── app.js
│   ├── i18n.js
│   ├── index.html
│   ├── private.html
│   ├── public.html
│   └── style.css
├── venv/                 # Python Virtual Environment (omitted internal libs)
├── database.db           # SQLite Database file
├── README.md
├── requirements.txt
└── path                  # File/Directory

