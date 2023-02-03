FROM ubuntu as package

RUN apt-get update
RUN apt-get install build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils python3 -y
RUN apt-get install libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev -y
RUN apt-get install libboost-all-dev -y
RUN apt-get install libdb5.3-dev libdb5.3++-dev -y
RUN apt-get install libminiupnpc-dev -y
RUN apt-get install libzmq3-dev -y
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get install libqt5gui5 libqt5core5a libqt5dbus5 qttools5-dev qttools5-dev-tools libprotobuf-dev protobuf-compiler -y
RUN apt-get install libqrencode-dev -y
RUN apt-get install curl -y

WORKDIR /dingocoin
COPY . /dingocoin

RUN ./autogen.sh
RUN ./configure --with-incompatible-bdb --with-miniupnpc
RUN make dist
RUN make -C depends download
RUN tar -czf depends.tar.gz depends
# RUN mkdir -p /artifact
# RUN mv depends.tar.gz dingocoin-*.tar.gz /artifact

FROM ubuntu as build

RUN apt-get update
RUN apt-get install build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils python3 -y
RUN apt-get install libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev -y
RUN apt-get install libboost-all-dev -y
RUN apt-get install libdb5.3-dev libdb5.3++-dev -y
RUN apt-get install libminiupnpc-dev -y
RUN apt-get install libzmq3-dev -y
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get install libqt5gui5 libqt5core5a libqt5dbus5 qttools5-dev qttools5-dev-tools libprotobuf-dev protobuf-compiler -y
RUN apt-get install libqrencode-dev -y
RUN apt-get install curl -y
RUN apt-get install -y python3-zmq make

WORKDIR /dingocoin
COPY --from=package /dingocoin/depends.tar.gz /dingocoin/depends.tar.gz
COPY --from=package /dingocoin/dingocoin-*.tar.gz /dingocoin/dingocoin.tar.gz
RUN tar -xzf depends.tar.gz
RUN tar -xzf dingocoin.tar.gz --strip-components=1
RUN make -C depends -j$(nproc)
RUN ./configure --prefix=$(realpath depends/x86_64-pc-linux-gnu)
RUN make -j$(nproc)

FROM ubuntu as cli
WORKDIR /dingocoin
COPY --from=build /dingocoin/src/dingocoind /dingocoin/dingocoind
COPY --from=build /dingocoin/src/dingocoin-cli /dingocoin/dingocoin-cli
COPY --from=build /dingocoin/src/dingocoin-tx /dingocoin/dingocoin-tx

ENV PATH="${PATH}:/dingocoin"

ENTRYPOINT [ "dingocoind" ]
