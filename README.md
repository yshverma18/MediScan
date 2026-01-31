
MediScan - Medi Scan – Cancer Skin
Classification mobile app

MediScan is a full-stack AI system for automated skin lesion analysis, aiming to bridge the gap between computer vision research and real-world healthcare applications. The platform leverages deep learning, scalable back-end technologies, and a mobile-first approach to deliver real-time dermatological information and incorporate safety and validation features.
This project showcases how contemporary machine learning models can be applied to build a production-oriented system, not only considering the accuracy of machine learning models but also ensuring reliability, trust, and responsible AI design.
 

Problem Statement
Skin cancer is one of the most prevalent and growing forms of cancer globally. Early detection is critical in raising survival rates for those suffering from skin cancer. However, access to dermatological screening remains limited for many groups.
MediScan aims to create an intelligent, accessible, and privacy-focused system to help users recognize potentially harmful skin lesions and seek timely medical advice.



System Overview
MediScan is a distributed ML system consisting of three primary layers. They include:

Mobile Interface (Flutter Framework):
1.	Image capture and gallery upload
2.	Visualization of predictions in real-time
3.	Confidence-based user interfaces
Inference Backend (FastAPI Framework):
1.	REST-based machine learning inference APIs
2.	Deterministic preprocessing pipeline
3.	TensorFlow Lite model serving
4.	Safety filters and confidence thresholds

ML Training Pipeline (PyTorch Framework):
1.	Transfer learning using ResNet-18 model
2.	Structured data preprocessing
3.	GPU-accelerated training
4.	Exportable inference artifacts

Core Capabilities
Intelligent Image Classification:
1.	7-class dermatological lesion classification
2.	Deep convolutional neural network using transfer learning
3.	Softmax probability-based outputs
Safety First Inference:
1.	Skin detection validation
2.	Low confidence rejection
3.	Invalid input filtering
Production-Oriented Architecture:
1.	REST-based machine learning inference APIs
2.	Model loaded once in memory
3.	Frontend agnostic design
4.	Cloud deployable inference backend


Supported Diagnostic Classes
Code	Medical Category
1.	akiec	Actinic Keratosis
2.	bcc	Basal Cell Carcinoma
3.	bkl	Benign Keratosis
4.	df	Dermatofibroma
5.	mel	Melanoma
6.	nv	Nevus (Mole)
7.	vasc	Vascular Lesions

Machine Learning Approach

Dataset
HAM10000 augmented dermatology dataset
38,569 labeled dermoscopic images with balanced class distribution

Data Strategy
1.	70% for training, 15% for validation, and 15% for testing
2.	Stratified sampling for classes
3.	Extensive data augmentation for generalization


Preprocessing
1.	Image resizing to 224x224 pixels
2.	ImageNet normalization
3.	Random flip and rotation (training only)

Model Architecture
1.	ResNet-18 model (pre-trained model)
2.	Final layer modification for 7 classes
3.	Transfer learning for faster convergence

Training Configuration
1.	Loss function: Cross entropy
2.	Optimizer: Adam
3.	Learning rate: 0.001
4.	GPU acceleration using CUDA


Backend API Design
The FastAPI backend provides a minimal, production-ready API interface:
Endpoint Description
•	GET /health	Service and model health check
•	POST /users/register	User creation
•	POST /users/login	Authentication
•	POST /predict	Image inference
•	GET /predictions/history	Prediction records
The /predict endpoint handles the full inference pipeline:
•	Input validation
•	Preprocessing
•	TFLite inference
•	Safety filtering
•	Structured JSON response
 
Confidence & Safety Controls
MediScan departs from common ML showcase code by providing strong safety features:
•	Skin Detection Filter
•	Filters out images lacking adequate skin regions.
•	Confidence Thresholding
•	Returns "uncertain" for predictions below 70% confidence.
•	Invalid Input Handling
•	Prevents deceptive predictions on unrelated images.
•	These are critical for safe AI system behavior in medical applications.
 
Data Persistence Strategy
1.MediScan provides a SQLAlchemy database layer (SQLite) with support for database schemas for:
•	User profiles
•	Prediction records
Currently, prediction storage is optional and turned off by default for a privacy-conscious design. The data layer is infrastructure for future functionality like:
•	Prediction history
•	Model monitoring
•	Clinical audit trails
 
2.Technology Stack

Frontend
•	Flutter (Dart)

Backend
•	FastAPI
•	SQLAlchemy
•	OpenCV
•	Pillow

Machine Learning
•	PyTorch
•	TensorFlow Lite
•	NumPy
•	Scikit-learn

3.Deployment (Planned)
•	Google Cloud Platform
•	Cloud Run / Vertex AI
•	GPU-accelerated inference services

4.Execution (Local Development)
•	Backend
•	cd backend
•	pip install -r requirements.txt
•	uvicorn app.main:app --reload
•	Mobile App
•	cd flutter
•	flutter pub get
•	flutter run
 


Future Roadmap
The MediScan application is intended as part of a broader scope for an electronic healthcare application. Future development will include:
Explainable AI
•	Grad-CAM heatmap visualizations
•	Model interpretability layer
Cloud AI Services
•	GCP-based deployment
•	Scalable infrastructure for inference
•	Centralized model updates
Clinical Integration
•	Location-based doctor discovery
•	Scheduling appointments
•	Automated medical report sharing
Digital Healthcare Features
•	Prescription management
•	Follow-up reminders
•	Patient history tracking
Regulatory Readiness
•	Data encryption
•	User consent management
•	HIPAA and GDPR compliance
 
Professional Perspective
The MediScan application is engineered as more than just an academic research project. It represents actual ML system design patterns and principles:
•	Separation of concerns (Model, API, UI)
•	Deployment-aware architecture
•	Safety and validation logic
•	Scalable cloud infrastructure
•	User-centered product development
This application represents not just ML development prowess, but ML engineering, ML system design, and overall, AI product development expertise.
 
Disclaimer
The application is intended for academic and research purposes only.
The application does not replace actual medical diagnosis and decision-making.
 

Author
Yash Verma
Backend & AI Engineer
MS in Computer Science

