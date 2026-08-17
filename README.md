# Bitbucket MCP Server

MCP (Model Context Protocol) Server untuk Bitbucket yang memungkinkan Claude Desktop membaca repository dan source code dari Bitbucket Anda.

## ✨ Fitur

Server ini menyediakan tools berikut:

| Tool | Deskripsi |
|------|-----------|
| `list_workspaces` | Melihat semua workspace Bitbucket |
| `list_repositories` | Melihat semua repository di workspace |
| `get_repository` | Detail informasi repository |
| `list_branches` | Melihat semua branch di repository |
| `list_commits` | Melihat commit history |
| `get_commit` | Detail commit tertentu |
| `browse_directory` | Menjelajahi struktur folder repository |
| `get_file_content` | Membaca isi file source code |
| `search_code` | Mencari kode dalam repository |
| `get_pull_requests` | Melihat pull requests |
| `get_readme` | Membaca file README |
| `get_commit_diff` | Melihat diff perubahan commit |

## 📋 Prasyarat

1. **Node.js** versi 18 atau lebih baru
2. **Bitbucket Account** dengan akses ke repository
3. **Bitbucket App Password** (bukan password login biasa)

### Cara Membuat Bitbucket App Password

1. Login ke [Bitbucket](https://bitbucket.org)
2. Klik avatar Anda di pojok kanan bawah → **Personal settings**
3. Pilih **App passwords** di menu kiri
4. Klik **Create app password**
5. Beri label (misal: "MCP Server")
6. Beri permission berikut:
   - **Repositories**: `Read`
   - **Pull requests**: `Read`
   - **Workspace**: `Read`
7. Klik **Create** dan **simpan password** yang muncul (hanya muncul sekali)

## 🚀 Instalasi

```bash
# Clone atau masuk ke folder project
cd d:\Projects\Pribadi\MCP_bitbucket

# Install dependencies
npm install

# Build project
npm run build
```

## 🔧 Konfigurasi Claude Desktop

### 1. Buka file konfigurasi Claude Desktop

**Windows:**
```
%APPDATA%\Claude\claude_desktop_config.json
```

**macOS:**
```
~/Library/Application Support/Claude/claude_desktop_config.json
```

### 2. Tambahkan konfigurasi MCP Server

Tambahkan entri berikut ke file `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "bitbucket": {
      "command": "node",
      "args": ["d:\\Projects\\Pribadi\\MCP_bitbucket\\dist\\index.js"],
      "env": {
        "BITBUCKET_USERNAME": "username-bitbucket-anda",
        "BITBUCKET_APP_PASSWORD": "app-password-anda",
        "BITBUCKET_WORKSPACE": "workspace-slug-anda"
      }
    }
  }
}
```

**Catatan:**
- Ganti `username-bitbucket-anda` dengan username Bitbucket Anda
- Ganti `app-password-anda` dengan App Password yang Anda buat
- Ganti `workspace-slug-anda` dengan slug workspace Anda (opsional, bisa juga di-pass sebagai parameter tool)
- Gunakan double backslash (`\\`) untuk path di Windows

### 3. Restart Claude Desktop

Tutup dan buka kembali Claude Desktop. Server akan otomatis terhubung.

## 💡 Cara Penggunaan

Setelah terhubung, Anda bisa bertanya kepada Claude seperti:

- *"Tampilkan semua repository di workspace saya"*
- *"Baca isi file `src/index.ts` di repository `my-project`"*
- *"Tampilkan struktur folder repository `backend-api`"*
- *"Cari kode yang menggunakan fungsi `validateUser` di repository `auth-service`"*
- *"Tampilkan commit terbaru di branch `develop`"*
- *"Baca README dari repository `frontend-app`"*
- *"Tampilkan pull request yang masih open"*

## 🛠️ Development

```bash
# Build
npm run build

# Jalankan manual (untuk testing)
BITBUCKET_USERNAME=user BITBUCKET_APP_PASSWORD=pass npm start
```

## 📁 Struktur Project

```
MCP_bitbucket/
├── src/
│   ├── index.ts              # Entry point & MCP Server setup
│   ├── bitbucket-client.ts   # Bitbucket API client
│   └── tools.ts              # Definisi MCP tools
├── dist/                     # Compiled JavaScript (generated)
├── package.json
├── tsconfig.json
└── README.md
```

## 🔒 Keamanan

- App Password disimpan dalam environment variable, bukan di code
- App Password hanya punya akses baca (read-only)
- Semua komunikasi menggunakan HTTPS
- Jangan commit App Password ke repository