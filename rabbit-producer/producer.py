import pika
import logging
import os

credentials = pika.PlainCredentials("admin", "admin")

logging.basicConfig(level=logging.DEBUG)
logging.getLogger("pika").setLevel(logging.DEBUG)

host = os.environ.get("RABBITMQ_HOST", "127.0.0.1")
connection = pika.BlockingConnection(pika.ConnectionParameters(
    host=host,
    port=1234,
    credentials=credentials)
)
channel = connection.channel()

channel.queue_declare(queue='hello')

channel.basic_publish(exchange='', routing_key='hello', body='Hello World')
print("Message from proucer was sent")

connection.close()
