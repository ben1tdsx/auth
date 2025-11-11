<template>
  <div class="container">
    <div class="login-card">
      <h1>File Browser Login</h1>
      <p class="subtitle">Access protected files in node_access_control</p>
      
      <form @submit.prevent="handleLogin">
        <div class="form-group">
          <label for="username">Username</label>
          <input 
            type="text" 
            id="username" 
            v-model="username" 
            required 
            autofocus
          />
        </div>
        
        <div class="form-group">
          <label for="password">Password</label>
          <input 
            type="password" 
            id="password" 
            v-model="password" 
            required
          />
        </div>
        
        <div v-if="errorMessage" class="error-message">
          {{ errorMessage }}
        </div>
        
        <button 
          type="submit" 
          class="btn btn-primary" 
          :disabled="isLoading"
        >
          <span v-if="!isLoading">Login</span>
          <span v-else>Logging in...</span>
        </button>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';

const router = useRouter();
const username = ref('');
const password = ref('');
const errorMessage = ref('');
const isLoading = ref(false);

const handleLogin = async () => {
  errorMessage.value = '';
  isLoading.value = true;
  
  try {
    const response = await fetch('/api/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ 
        username: username.value, 
        password: password.value 
      })
    });
    
    const data = await response.json();
    
    if (data.success) {
      // Redirect to file browser
      router.push('/');
    } else {
      errorMessage.value = data.message || 'Login failed';
    }
  } catch (error) {
    errorMessage.value = 'Error connecting to server. Please try again.';
  } finally {
    isLoading.value = false;
  }
};
</script>

