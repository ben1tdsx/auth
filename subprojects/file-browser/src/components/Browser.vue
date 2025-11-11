<template>
  <div class="browser-container">
    <header class="browser-header">
      <h1>File Browser</h1>
      <div class="header-actions">
        <span class="username">{{ username }}</span>
        <button class="btn btn-secondary" @click="handleLogout">Logout</button>
      </div>
    </header>

    <div class="browser-content">
      <nav class="breadcrumb">
        <a href="#" @click.prevent="navigateToPath('/')">Home</a>
        <template v-for="(part, index) in breadcrumbParts" :key="index">
          <span> / </span>
          <a href="#" @click.prevent="navigateToPath(breadcrumbPaths[index])">
            {{ part }}
          </a>
        </template>
      </nav>

      <div class="toolbar">
        <button class="btn btn-small" @click="loadDirectory(currentPath)">
          Refresh
        </button>
        <span class="current-path">{{ currentPath }}</span>
      </div>

      <div class="file-list-container">
        <div v-if="isLoading" class="loading">
          Loading...
        </div>
        <div v-if="errorMessage" class="error-message">
          {{ errorMessage }}
        </div>
        <table v-if="!isLoading && !errorMessage" class="file-table">
          <thead>
            <tr>
              <th class="col-name">Name</th>
              <th class="col-type">Type</th>
              <th class="col-size">Size</th>
              <th class="col-modified">Modified</th>
              <th class="col-actions">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="files.length === 0">
              <td colspan="5" class="empty-message">Directory is empty</td>
            </tr>
            <tr v-for="file in files" :key="file.path" class="file-row">
              <td class="col-name">
                <span class="file-icon">{{ getFileIcon(file.type, file.name) }}</span>
                <a 
                  href="#" 
                  class="file-link" 
                  @click.prevent="handleFileClick(file)"
                >
                  {{ file.name }}
                </a>
              </td>
              <td class="col-type">{{ file.type }}</td>
              <td class="col-size">{{ formatSize(file.size) }}</td>
              <td class="col-modified">{{ formatDate(file.modified) }}</td>
              <td class="col-actions">
                <a 
                  v-if="file.type === 'file'"
                  :href="`/api/download?path=${encodeURIComponent(file.path)}`"
                  class="btn-download"
                  download
                >
                  Download
                </a>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';

const router = useRouter();
const currentPath = ref('/');
const files = ref([]);
const isLoading = ref(false);
const errorMessage = ref('');
const username = ref('');

const breadcrumbParts = computed(() => {
  return currentPath.value.split('/').filter(p => p);
});

const breadcrumbPaths = computed(() => {
  const parts = breadcrumbParts.value;
  const paths = [];
  let current = '';
  parts.forEach(part => {
    current += '/' + part;
    paths.push(current);
  });
  return paths;
});

const formatSize = (bytes) => {
  if (bytes === null || bytes === undefined) return '-';
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
};

const formatDate = (dateString) => {
  const date = new Date(dateString);
  return date.toLocaleString();
};

const getFileIcon = (type, name) => {
  if (type === 'directory') {
    return '📁';
  }
  const ext = name.split('.').pop().toLowerCase();
  const icons = {
    'jpg': '🖼️', 'jpeg': '🖼️', 'png': '🖼️', 'gif': '🖼️', 'svg': '🖼️',
    'mp4': '🎥', 'avi': '🎥', 'mov': '🎥', 'mkv': '🎥',
    'mp3': '🎵', 'wav': '🎵', 'flac': '🎵',
    'pdf': '📄', 'doc': '📄', 'docx': '📄',
    'zip': '📦', 'tar': '📦', 'gz': '📦',
    'txt': '📝', 'md': '📝',
    'js': '📜', 'json': '📜', 'html': '📜', 'css': '📜'
  };
  return icons[ext] || '📄';
};

const loadDirectory = async (path) => {
  isLoading.value = true;
  errorMessage.value = '';
  files.value = [];

  try {
    const response = await fetch(`/api/files?path=${encodeURIComponent(path)}`);
    const data = await response.json();

    if (response.ok) {
      currentPath.value = data.path;
      files.value = data.files;
    } else {
      errorMessage.value = data.error || 'Error loading directory';
      if (response.status === 401 || response.status === 403) {
        router.push('/login');
      }
    }
  } catch (error) {
    errorMessage.value = 'Error connecting to server';
  } finally {
    isLoading.value = false;
  }
};

const handleFileClick = (file) => {
  if (file.type === 'directory') {
    loadDirectory(file.path);
  } else {
    window.location.href = `/api/download?path=${encodeURIComponent(file.path)}`;
  }
};

const navigateToPath = (path) => {
  loadDirectory(path);
};

const handleLogout = async () => {
  try {
    await fetch('/logout', { method: 'POST' });
    router.push('/login');
  } catch (error) {
    console.error('Logout error:', error);
    router.push('/login');
  }
};

onMounted(async () => {
  // Get username and load directory
  try {
    // Get username
    const userResponse = await fetch('/api/user');
    if (userResponse.ok) {
      const userData = await userResponse.json();
      username.value = userData.username || 'User';
    }
    
    // Load directory
    await loadDirectory('/');
  } catch (error) {
    console.error('Init error:', error);
    router.push('/login');
  }
});
</script>

