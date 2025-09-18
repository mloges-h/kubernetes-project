### **Overview**

This repository contains all the necessary files and documentation for a DevOps intern assignment. The project demonstrates the deployment of a Python Flask application with a MongoDB backend on a Kubernetes cluster, with a focus on containerization, orchestration, persistent storage, and public exposure.

-----

### **Part 1: Local Setup & Dockerization**

This section outlines the initial setup and local validation of the application using Docker and `docker-compose`.

1.  **Project Creation and Environment Setup**

      * Created the project directory: `mkdir flask-mongodb-app && cd flask-mongodb-app`
      * Set up a Python virtual environment: `python3 -m venv venv`
      * Activated the virtual environment: `source venv/bin/activate`

2.  **Application Code & Dependencies**

      * Created the `app.py` Flask application file.
      * Created the `requirements.txt` file for Python dependencies.
      * Created a `.env` file for the MongoDB connection string.

3.  **Containerization with Docker Compose**

      * Wrote a `Dockerfile` to containerize the Flask application.
      * Wrote a `docker-compose.yml` file to orchestrate the Flask and MongoDB containers for local testing.
      * Built and ran the containers:
        ```bash
        docker-compose build
        docker-compose up -d
        ```

4.  **Local Testing**

      * Verified the local application was running and connected to the database:
        ```bash
        curl http://localhost:5000/
        curl -X POST -H "Content-Type: application/json" -d '{"sampleKey":"sampleValue"}' http://localhost:5000/data
        ```

-----

### **Part 2: Kubernetes Deployment**

This section details the steps to deploy the application on a Kubernetes cluster, including all required resources and configurations.

1.  **Installing `kubectl` and Minikube**

      * Downloaded and verified `kubectl`:
        ```bash
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
        echo "$(cat kubectl.sha256) kubectl" | sha256sum --check
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        ```
      * Installed Minikube using the `.deb` package:
        ```bash
        curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb
        sudo dpkg -i minikube_latest_amd64.deb
        ```

2.  **Building and Pushing the Docker Image**

      * Built the final Docker image for the Flask application:
        ```bash
        docker build -t mlogesh/flask-mongodb-app:1.0 .
        ```
      * Logged into Docker Hub and pushed the image to a container registry:
        ```bash
        docker login
        docker push mlogesh/flask-mongodb-app:1.0
        ```

3.  **Kubernetes Manifests**

      * Created the following YAML files to define the Kubernetes resources:
          * `db-creds.yaml` (for database authentication)
          * `mongodb-statefulset.yaml`
          * `mongodb-service.yaml`
          * `flask-deployment.yaml`
          * `flask-service.yaml`
          * `hpa.yaml`

4.  **Deployment to Minikube**

      * Applied all the Kubernetes manifests to the Minikube cluster:
        ```bash
        kubectl apply -f .
        ```

5.  **Public Access with NGINX Reverse Proxy**

      * Used a standalone NGINX container to act as a reverse proxy, making the application publicly accessible on port 80 of the EC2 instance.
      * The NGINX container was run in `--network=host` mode to ensure it could connect to the Minikube service.
        ```bash
        docker run --name nginx-proxy --network=host -d nginx
        docker cp nginx.conf nginx-proxy:/etc/nginx/nginx.conf
        docker exec nginx-proxy nginx -s reload
        ```

-----

### **Resource Verification**

Verified that all Kubernetes resources were deployed successfully with the following commands:

  * **Deployments & StatefulSets:** `kubectl get deployments`, `kubectl get statefulsets`
  * **Services:** `kubectl get services`
  * **Volumes:** `kubectl get pvc`, `kubectl get pv`
  * **Autoscaler:** `kubectl get hpa`

-----
In your `README.md` file, you should include the following explanation for DNS resolution. This answers the specific requirement from your assignment by explaining how the Flask application finds and connects to the MongoDB service.

---

### **6. DNS Resolution**

Within a Kubernetes cluster, DNS resolution allows pods to discover and communicate with each other using simple, human-readable names instead of hardcoding IP addresses. Kubernetes automatically configures a DNS server for the cluster, which manages records for all services and pods.

When your Flask application pod needs to connect to the MongoDB database, it doesn't need to know the MongoDB pod's IP address. Instead, it uses the **service name** as the hostname.

For example, since your MongoDB service is named `mongodb`, your Flask application can simply connect to `mongodb:27017`. The DNS system within Kubernetes automatically resolves the `mongodb` hostname to the correct internal ClusterIP address of the MongoDB service.

This approach offers several key benefits:
* **Decoupling:** The application is no longer dependent on a specific IP address. If the MongoDB pod or service IP changes, the connection string in the Flask application remains the same.
* **Service Discovery:** It provides a reliable and built-in method for pods to find other services within the cluster.
* **Load Balancing:** The DNS record for a service often resolves to multiple pod IPs, allowing for simple load balancing across replicas.

### **Design Choices & Explanations**

  * **`StatefulSet` for MongoDB:** Chosen for its stable network identity and ability to use Persistent Volume Claims, guaranteeing data persistence even if pods are rescheduled.
  * **`Deployment` for Flask:** Ideal for the stateless application, as it manages replica sets and provides a declarative way to manage the application's lifecycle.
  * **`ClusterIP` for MongoDB Service:** Ensures that MongoDB is only accessible from within the cluster, a critical security measure.
  * **`NodePort` for Flask Service:** Exposes the application on a specific port on the Minikube node, allowing the NGINX proxy to forward traffic to it.
  * **`--network=host` for NGINX:** This was a crucial fix to resolve the `504 Gateway Time-out` error. It allowed the NGINX container to bypass its isolated network and access the Minikube cluster's internal IP address on the host machine.

-----

### **Testing Scenarios**

  * **Application Functionality:**

      * **Method:** Performed `curl` requests to the public IP address of the EC2 instance.
      * **Result:** The application's endpoints (`/` and `/data`) responded as expected, confirming public access and database connectivity.

  * **Autoscaling (`Cookie Point`):**

      * **Method:** Used `ab` (Apache Bench) to generate a high load on the application.
      * **Result:** The HPA successfully scaled the Flask pods from 2 to 5 to handle the increased CPU utilization. After the load test, the HPA scaled the pods back down to the minimum of 2. This proves the autoscaling is working.
