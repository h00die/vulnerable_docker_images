FROM python:3.11-slim
WORKDIR /app
RUN pip install --no-cache-dir "flask==2.2.5" "werkzeug==2.2.3"
COPY app.py .
ENV FLASK_ENV=development
ENV WERKZEUG_DEBUG_PIN=off
CMD ["python3", "-u", "app.py"]
