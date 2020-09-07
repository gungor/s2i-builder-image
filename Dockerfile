FROM registry.redhat.io/rhel7/rhel
USER root

COPY cct_module/jboss/container/user /tmp/scripts/jboss.container.user
ENV HOME="/home/jboss" 
USER root
RUN [ "sh", "-x", "/tmp/scripts/jboss.container.user/configure.sh" ]

#############################################################################################
# install maven
RUN mkdir /tmp/tools && \
	curl -o /tmp/tools/apache-maven-3.6.3-bin.tar.gz -L https://downloads.apache.org/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz && \ 
	tar -zxvf /tmp/tools/apache-maven-3.6.3-bin.tar.gz -C /tmp/tools && \ 
	mkdir /usr/lib/maven && \ 
	mv /tmp/tools/apache-maven-3.6.3/* /usr/lib/maven && \ 
	rm /tmp/tools/apache-maven-3.6.3-bin.tar.gz
ENV PATH="/usr/lib/maven/bin:${PATH}"

# install java
# openj9 java:14

RUN curl -o /tmp/tools/jdk.tar.gz -L https://github.com/AdoptOpenJDK/openjdk14-binaries/releases/download/jdk-14.0.2%2B12_openj9-0.21.0/OpenJDK14U-jdk_x64_linux_openj9_14.0.2_12_openj9-0.21.0.tar.gz && \ 
	tar -zxvf /tmp/tools/jdk.tar.gz -C /tmp/tools && \ 
	mkdir /usr/lib/jvm && \ 
	mv /tmp/tools/jdk-14.0.2+12/* /usr/lib/jvm && \ 
	rm /tmp/tools/jdk.tar.gz

ENV PATH="/usr/lib/jvm/bin:${PATH}"
ENV JAVA_HOME="/usr/lib/jvm" 

ENV S2I_SOURCE_DEPLOYMENTS_FILTER="*" 
LABEL \
    io.openshift.s2i.destination="/tmp"  \
    io.openshift.s2i.scripts-url="image:///usr/local/s2i"  \
    org.jboss.container.deployments-dir="/deployments" 

#############################################################################################
COPY cct_module/jboss/container/s2i/core/bash /tmp/scripts/jboss.container.s2i.core.bash

ENV JBOSS_CONTAINER_S2I_CORE_MODULE="/opt/jboss/container/s2i/core/" 

USER root
RUN [ "sh", "-x", "/tmp/scripts/jboss.container.s2i.core.bash/configure.sh" ]

#############################################################################################
COPY cct_module/jboss/container/java/jvm/bash /tmp/scripts/jboss.container.java.jvm.bash

ENV JBOSS_CONTAINER_JAVA_JVM_MODULE="/opt/jboss/container/java/jvm" 

USER root
RUN [ "sh", "-x", "/tmp/scripts/jboss.container.java.jvm.bash/configure.sh" ]
USER root
RUN [ "sh", "-x", "/tmp/scripts/jboss.container.java.jvm.bash/backward_compatibility.sh" ]

#############################################################################################
COPY cct_module/jboss/container/util/logging/bash /tmp/scripts/jboss.container.util.logging.bash

ENV JBOSS_CONTAINER_UTIL_LOGGING_MODULE="/opt/jboss/container/util/logging/" 
USER root
RUN [ "sh", "-x", "/tmp/scripts/jboss.container.util.logging.bash/configure.sh" ]
USER root
RUN [ "sh", "-x", "/tmp/scripts/jboss.container.util.logging.bash/backward_compatibility.sh" ]

#############################################################################################
COPY cct_module/jboss/container/maven/s2i /tmp/scripts/jboss.container.maven.s2i.bash
COPY maven.sh /opt/jboss/container/maven/default/
COPY jboss-settings.xml /opt/jboss/container/maven/default/

ENV JBOSS_CONTAINER_MAVEN_S2I_MODULE="/opt/jboss/container/maven/s2i" 
ENV JBOSS_CONTAINER_MAVEN_DEFAULT_MODULE="/opt/jboss/container/maven/default"	

USER root
RUN [ "sh", "-x", "/tmp/scripts/jboss.container.maven.s2i.bash/configure.sh" ]

#############################################################################################
COPY cct_module/jboss/container/java/run/bash /tmp/scripts/jboss.container.java.run.bash
ENV \
    JAVA_DATA_DIR="/deployments/data" \
    JBOSS_CONTAINER_JAVA_RUN_MODULE="/opt/jboss/container/java/run" 

USER root
RUN [ "sh", "-x", "/tmp/scripts/jboss.container.java.run.bash/configure.sh" ]
USER root
RUN [ "sh", "-x", "/tmp/scripts/jboss.container.java.run.bash/backward_compatibility.sh" ]

#############################################################################################
COPY cct_module/jboss/container/java/s2i/bash /tmp/scripts/jboss.container.java.s2i.bash

ENV \
    JBOSS_CONTAINER_JAVA_S2I_MODULE="/opt/jboss/container/java/s2i" \
    S2I_SOURCE_DEPLOYMENTS_FILTER="*.jar" 
USER root
RUN [ "sh", "-x", "/tmp/scripts/jboss.container.java.s2i.bash/configure.sh" ]

#############################################################################################

COPY run /usr/local/s2i/
ENV PATH="$PATH:"/usr/local/s2i"" 

EXPOSE 8080 8443

USER root
RUN [ ! -d /tmp/scripts ] || rm -rf /tmp/scripts && [ ! -d /tmp/artifacts ] || rm -rf /tmp/artifacts && [ ! -d /tmp/tools ] || rm -rf /tmp/tools

USER 185
WORKDIR /home/jboss
CMD ["/usr/local/s2i/run"]

