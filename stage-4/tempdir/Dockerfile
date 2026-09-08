FROM python
WORKDIR /home/myapp
COPY ./requirements.txt .
COPY ./static ./static
COPY ./templates ./templates
COPY ./app.py .
RUN sed -i '/apturl/d' requirements.txt && \
    pip install --no-cache-dir -r requirements.txt
EXPOSE 8080
CMD ["python3", "app.py"]
