# ICP Greeting App

A simple Internet Computer (ICP) dApp that takes a user's name and returns a personalized greeting.

## 📌 Features  
- Accepts a name input and returns a personalized greeting from the backend.  
- Uses **DFINITY Canisters** for backend logic.  
- Built with **React, Vite, and DFINITY SDK**.

## 🛠 Tech Stack  
- **Frontend:** React, Vite  
- **Backend:** Rust, ICP Canisters  
- **Blockchain:** Internet Computer (ICP)  


## Prerequisites

Ensure you have the following installed:

- [DFX SDK](https://internetcomputer.org/docs/current/developer-docs/setup/install)
- Node.js and npm (for frontend)
- Rust and cargo (for backend)

## Setup

Clone the repository:

```sh
git clone https://github.com/Pragyaa3/Pragya_QuadB_Tech.git
cd Pragya_QuadB_Tech/week1/day1/icp_greeting
```

Install dependencies:

```sh
npm install
```

## Running the Project

Start the ICP local network:

```sh
dfx start --background
```

Deploy the canisters:

```sh
dfx deploy
```

## Accessing the Application

Once deployed, open the frontend in your browser:

```sh
dfx canister call icp_greeting_backend greet '("Hello, ICP!")'
dfx canister id icp_greeting_frontend
```

Use the provided frontend canister ID URL to access the dApp.
