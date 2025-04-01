import pika
import logging
import os
import time
import random

# Настройка логирования
logging.basicConfig(level=logging.INFO)

# Подключение к RabbitMQ
credentials = pika.PlainCredentials("admin", "admin")
host = os.environ.get("RABBITMQ_HOST", "127.0.0.1")
port = 1234

def generate_message(index):
    return f"Message #{index} - {random.randint(1000, 9999)}"

def main():
    connection = pika.BlockingConnection(pika.ConnectionParameters(
        host=host,
        port=port,
        credentials=credentials
    ))
    channel = connection.channel()
    channel.queue_declare(queue='hello')

    for i in range(1, 100):
        message = generate_message(i)
        channel.basic_publish(
            exchange='',
            routing_key='hello',
            body=message.encode(),
            properties=pika.BasicProperties(delivery_mode=2)
        )
        logging.info(f"[x] Sent: {message}")
        time.sleep(1.5)

    connection.close()
    logging.info("All messages sent and connection closed.")

if __name__ == "__main__":
    main()
