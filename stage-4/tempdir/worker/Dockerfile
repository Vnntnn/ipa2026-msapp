FROM python
WORKDIR /home/worker
COPY ./*.py .
RUN pip install --no-cache-dir pika pymongo "paramiko<4" netmiko ntc-templates
CMD ["python3", "consumer.py"]
