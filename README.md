# **MyClub – Sports Club Management Application**

MyClub is a sports club management application that allows users to browse and purchase products, follow matches, buy tickets, and manage their memberships. The system is built using a .NET Web API backend, with Flutter-based desktop and mobile applications.

---

## **How to Run the Project**

### **Environment Setup**

1. **Extract MyClub_env.zip**

   * Extract the file `env_file.zip` (password: **fit**)
   * Copy the `.env` file into the root MyClub folder (the same directory where `docker-compose.yml` is located)

2. **Start Backend Services**

   ```bash
   docker compose up --build
   ```

3. **Extract the Desktop and Mobile Applications**

   * Extract `fit-build-2025-25-08.zip`
   * Locate the `.apk` file for the Android mobile app
   * Locate the `.exe` file for the Windows desktop app

---

## **Installing the Applications**

* **Desktop Application**: Run the `.exe` file
* **Mobile Application**: Install the `.apk` file on an Android device

---

## **Login Credentials**

### **Desktop Application**

* **Username:** admin
* **Password:** test

### **Mobile Application (Administrator)**

* **Username:** admin
* **Password:** test

### **Mobile Application (Regular Users)**

* **Username:** user
* **Password:** test

or

* **Username:** nihad123
* **Password:** test

---

## **Test Payment Credentials**

### **PayPal Test Account**

Use the following credentials to test purchasing tickets, memberships, and orders:

* **Email:** [sb-43ieux45361356@personal.example.com](mailto:sb-43ieux45361356@personal.example.com)
* **Password:** Test1234

### **Stripe Test Cards**

For testing Stripe payments, visit:
[https://docs.stripe.com/testing](https://docs.stripe.com/testing)
This page includes a variety of test cards for different testing scenarios.

---

## **RabbitMQ**

The project uses RabbitMQ to send information about orders and to support the password reset functionality.
