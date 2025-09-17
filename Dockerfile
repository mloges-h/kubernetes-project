# Use an official Python runtime as a parent image
FROM python:3.8-slim

# Set the working directory in the container
WORKDIR /app

# Copy the requirements file into the working directory
COPY requirements.txt .

# Install the Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code into the working directory
COPY . .

# Expose the port the app runs on
EXPOSE 5000

# Set environment variables for the application
ENV FLASK_APP=app.py
ENV FLASK_ENV=production

# Define the command to run the application
CMD ["flask", "run", "--host=0.0.0.0", "--port=5000"]
