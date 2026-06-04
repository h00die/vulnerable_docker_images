FROM python:3.11-slim

RUN pip install --no-cache-dir pyghmi

COPY bmc.py /bmc.py

# IPMI over LAN — UDP 623
EXPOSE 623/udp

CMD ["python3", "-u", "/bmc.py"]
