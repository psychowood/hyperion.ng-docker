FROM debian:bullseye

RUN apt-get update && \
    apt-get install -y wget gpg sudo && \
    wget -qO /tmp/hyperion.pub.key https://apt.hyperion-project.org/hyperion.pub.key && \
    gpg --dearmor -o - /tmp/hyperion.pub.key > /usr/share/keyrings/hyperion.pub.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/hyperion.pub.gpg] https://apt.hyperion-project.org/ bullseye main" > /etc/apt/sources.list.d/hyperion.list && \
    apt-get update && \
    apt-get install -y hyperion && \
    apt-get clean

EXPOSE 19400
EXPOSE 19444
EXPOSE 19445
EXPOSE 8090
EXPOSE 8092

RUN mkdir /config

ENV UID=1100
ENV GID=1100

RUN groupadd -f hyperion
RUN useradd -r -s /bin/bash -g hyperion hyperion

RUN echo "#!/bin/bash" > /start.sh
RUN echo "groupmod -g \$2 hyperion" >> /start.sh
RUN echo "usermod -u \$1 hyperion" >> /start.sh
RUN echo "sudo -u hyperion /usr/bin/hyperiond -v --service -u /config" >> /start.sh

RUN chmod 777 /start.sh

VOLUME /config

CMD [ "bash", "-c", "/start.sh ${UID} ${GID}" ]