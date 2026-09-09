import os, pika


def get_rabbit_config():
    return {
        "queue": os.environ.get("RABBITMQ_ROUTER_QUEUE_JOBS", "router_jobs"),
        "exchange": os.environ.get("RABBITMQ_ROUTER_EXCHANGE", "jobs"),
        "routing_key": os.environ.get(
            "RABBITMQ_ROUTER_ROUTING_KEY", "check_interfaces"
        ),
        "user": os.environ.get("RABBITMQ_DEFAULT_USER", "admin"),
        "password": os.environ.get("RABBITMQ_DEFAULT_PASS", "rabbitmq"),
    }


def produce(host: str, body: str):
    """
        producer function to send direct message to RabbitMQ
    """
    config = get_rabbit_config()
    credentials = pika.PlainCredentials(config["user"], config["password"])
    connection = pika.BlockingConnection(
        pika.ConnectionParameters(host=str(host), port=5672, credentials=credentials)
    )
    channel = connection.channel()

    channel.exchange_declare(
        exchange=config["exchange"], exchange_type="direct", durable=True
    )
    channel.queue_declare(queue=config["queue"], durable=True)
    channel.queue_bind(
        queue=config["queue"],
        exchange=config["exchange"],
        routing_key=config["routing_key"],
    )

    channel.basic_publish(
        exchange=config["exchange"],
        routing_key=config["routing_key"],
        body=str(body),
        properties=pika.BasicProperties(delivery_mode=2),
    )

    connection.close()
