FROM atendai/evolution-api:v2.2.3

# Update WhatsApp Web version number to match current version
# Evolution API v2.2.3 ships with 2.3000.1015901307 (outdated)
# Current version fetched from Baileys repo: 2.3000.1035194821
RUN echo '{"version":[2,3000,1035194821]}' > \
    /evolution/node_modules/@whiskeysockets/baileys/lib/Defaults/baileys-version.json
