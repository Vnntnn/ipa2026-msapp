FROM python
WORKDIR /home/scheduler
COPY ./requirements.txt .
COPY ./*.py .
RUN sed -i '/apturl/d' requirements.txt && \
    pip install --no-cache-dir -r requirements.txt
EXPOSE 2973
CMD ["python3", "scheduler.py"]
