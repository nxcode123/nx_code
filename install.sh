#!/data/data/com.termux/files/usr/bin/bash
echo -e "\033[1;32m[+] Menginstal NX_CODE Terminal...\033[0m"
rm -rf ~/.nx_code ~/nx_code.sh
curl -fsSL "https://raw.githubusercontent.com/nxcode123/nx_code/main/nx_code.sh" -o ~/nx_code.sh
chmod +x ~/nx_code.sh
sed -i 's/\xc2\xa0/ /g' ~/nx_code.sh
bash ~/nx_code.sh
