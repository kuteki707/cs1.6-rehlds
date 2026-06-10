FROM debian:bullseye-slim

# =========================================================================
# 1. INFRASTRUCTURE & EXTENSION VERSION CONTROLS
# =========================================================================
ENV HLDS_DIR="/home/steam/hlds"
ENV REHLDS_VERSION="3.15.0.896"
ENV REGAMEDLL_VERSION="5.26.0.668"
ENV METAMOD_VERSION="1.3.0.149"
ENV REUNION_VERSION="0.2.0.34"
ENV REAPI_VERSION="5.29.0.358"

# Proprietary blobs located in the local ./vendor directory
ENV WHBLOCKER_VERSION="1.5.697"
ENV REAIM_VERSION="0.2.2"

# =========================================================================
# 2. SYSTEM ARCHITECTURE & PREREQUISITES
# =========================================================================
RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget unzip tar lib32gcc-s1 lib32stdc++6 && \
    rm -rf /var/lib/apt/lists/* && \
    useradd -m -s /bin/bash steam

USER steam
WORKDIR /home/steam

# =========================================================================
# 3. BASE STEAMCMD & LEGACY GOLDSRC ENGINE DEPLOYMENT
# =========================================================================
RUN mkdir steamcmd && cd steamcmd && \
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - && \
    (./steamcmd.sh +force_install_dir ${HLDS_DIR} +login anonymous +app_update 90 -beta steam_legacy validate +quit || \
     ./steamcmd.sh +force_install_dir ${HLDS_DIR} +login anonymous +app_update 90 -beta steam_legacy validate +quit)

# =========================================================================
# 4. REHLDS ENGINE PATCH & RE-ROUTING ENGINE INTERFACES
# =========================================================================
RUN wget -q "https://github.com/dreamstalker/rehlds/releases/download/${REHLDS_VERSION}/rehlds-bin-${REHLDS_VERSION}.zip" && \
    unzip -q rehlds-bin-${REHLDS_VERSION}.zip && \
    cp -r bin/linux32/* ${HLDS_DIR}/ && \
    rm -rf rehlds-bin-${REHLDS_VERSION}.zip bin && \
    mkdir -p /home/steam/.steam/sdk32 && \
    ln -s /home/steam/steamcmd/linux32/steamclient.so /home/steam/.steam/sdk32/steamclient.so

# =========================================================================
# 5. MODDING CORE LAYER (Metamod-R & AMX Mod X)
# =========================================================================
WORKDIR ${HLDS_DIR}/cstrike
RUN mkdir -p addons/metamod/dlls addons/amxmodx /tmp/mm && \
    wget -q "https://github.com/rehlds/metamod-r/releases/download/${METAMOD_VERSION}/metamod-bin-${METAMOD_VERSION}.zip" -O /tmp/mm.zip && \
    unzip -q /tmp/mm.zip -d /tmp/mm && \
    # Forcefully grab the .so binary regardless of what the ZIP names it
    find /tmp/mm -type f -name "*.so" -exec cp {} addons/metamod/dlls/metamod.so \; && \
    rm -rf /tmp/mm.zip /tmp/mm && \
    # FIX: Destroy Windows carriage returns so the Linux linker doesn't corrupt string memory
    tr -d '\r' < liblist.gam > liblist.gam.tmp && mv liblist.gam.tmp liblist.gam && \
    # FIX: Overwrite the target execution line completely
    sed -i 's/.*gamedll_linux.*/gamedll_linux "addons\/metamod\/dlls\/metamod.so"/' liblist.gam && \
    wget -qO- "https://www.amxmodx.org/amxxdrop/1.10/amxmodx-latest-base-linux.tar.gz" | tar -zxf - && \
    wget -qO- "https://www.amxmodx.org/amxxdrop/1.10/amxmodx-latest-cstrike-linux.tar.gz" | tar -zxf -

# =========================================================================
# 6. AUTOMATED EXTENSION DOWNLOADS (Open Source)
# =========================================================================
# 6a. ReGameDLL_CS (Tournament Logic Core)
RUN mkdir -p /tmp/regame && \
    wget -q "https://github.com/s1lentq/ReGameDLL_CS/releases/download/${REGAMEDLL_VERSION}/regamedll-bin-${REGAMEDLL_VERSION}.zip" -O /tmp/regame.zip && \
    unzip -q /tmp/regame.zip -d /tmp/regame && \
    find /tmp/regame -type f -name "cs.so" -exec cp {} dlls/cs.so \; && \
    rm -rf /tmp/regame.zip /tmp/regame

# 6b. Reunion (Protocol Bridge)
RUN mkdir -p /tmp/reunion addons/reunion && \
    wget -q "https://github.com/rehlds/ReUnion/releases/download/${REUNION_VERSION}/reunion-${REUNION_VERSION}.zip" -O /tmp/reunion.zip && \
    unzip -q /tmp/reunion.zip -d /tmp/reunion && \
    find /tmp/reunion -type f -name "reunion_mm_i386.so" -exec mv {} addons/reunion/ \; && \
    find /tmp/reunion -type f -name "reunion.cfg" -exec cp {} ${HLDS_DIR}/cstrike/ \; && \
    rm -rf /tmp/reunion.zip /tmp/reunion

# 6c. ReAPI (Extended Game Logic Interface for AMXX)
RUN mkdir -p /tmp/reapi && \
    wget -q "https://github.com/rehlds/ReAPI/releases/download/${REAPI_VERSION}/reapi-bin-${REAPI_VERSION}.zip" -O /tmp/reapi.zip && \
    unzip -q /tmp/reapi.zip -d /tmp/reapi && \
    cp -r /tmp/reapi/addons/amxmodx/* addons/amxmodx/ && \
    rm -rf /tmp/reapi.zip /tmp/reapi

# =========================================================================
# 7. PROPRIETARY EXTENSION INJECTIONS (Closed Source from Vendor Folder)
# =========================================================================
# 7a. WHBlocker
COPY --chown=steam:steam vendor/whblocker_${WHBLOCKER_VERSION}.zip /tmp/whb.zip
RUN mkdir -p /tmp/whb addons/whblocker && \
    unzip -q /tmp/whb.zip -d /tmp/whb && \
    find /tmp/whb -type f -name "whblocker_mm_i386.so" -exec mv {} addons/whblocker/ \; && \
    find /tmp/whb -type f -name "whblocker.ini" -exec cp {} addons/whblocker/ \; && \
    rm -rf /tmp/whb.zip /tmp/whb

# 7b. ReAimDetector
COPY --chown=steam:steam vendor/reaimdetector_${REAIM_VERSION}.zip /tmp/reaim.zip
RUN mkdir -p /tmp/reaim addons/reaimdetector && \
    unzip -q /tmp/reaim.zip -d /tmp/reaim && \
    find /tmp/reaim -type f -name "reaimdetector_mm_i386.so" -exec mv {} addons/reaimdetector/ \; && \
    rm -rf /tmp/reaim.zip /tmp/reaim

# =========================================================================
# 8. METAMOD EXECUTION PRIORITY ROUTING
# =========================================================================
RUN echo "linux addons/reunion/reunion_mm_i386.so" > addons/metamod/plugins.ini && \
    echo "linux addons/whblocker/whblocker_mm_i386.so" >> addons/metamod/plugins.ini && \
    echo "linux addons/reaimdetector/reaimdetector_mm_i386.so" >> addons/metamod/plugins.ini && \
    echo "linux addons/amxmodx/dlls/amxmodx_mm_i386.so" >> addons/metamod/plugins.ini

# =========================================================================
# 9. CONTAINER CONFIGURATION MAPS & ENTRYPOINT TRIGGER
# =========================================================================
WORKDIR /home/steam
COPY --chown=steam:steam entrypoint.sh ./entrypoint.sh
RUN chmod +x entrypoint.sh

WORKDIR ${HLDS_DIR}
EXPOSE 27015/udp
ENV MAP="de_dust2" MAXPLAYERS="10" TICKRATE="1000"

ENTRYPOINT ["/home/steam/entrypoint.sh"]

