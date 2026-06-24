import os
from locust import HttpUser, task, between

class SmartStudentUser(HttpUser):
    # Wait between 1 to 3 seconds between tasks for a single user
    wait_time = between(1, 3)

    @task(3)
    def load_main_page(self):
        # Hit the home page
        self.client.get("/")
        
    @task(1)
    def load_login_page(self):
        # Hit the login page
        self.client.get("/login")
