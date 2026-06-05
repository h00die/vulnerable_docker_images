FROM python:3.11-slim
WORKDIR /app
RUN pip install --no-cache-dir flask
COPY app.py .
ENV FLASK_ENV=development
ENV WERKZEUG_DEBUG_PIN=off
CMD ["python3", "-u", "app.py"]
