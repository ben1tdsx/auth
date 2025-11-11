import { createApp } from 'vue';
import { createRouter, createWebHistory } from 'vue-router';
import App from './App.vue';
import Login from './components/Login.vue';
import Browser from './components/Browser.vue';
import './styles.css';

const routes = [
  { path: '/login', name: 'Login', component: Login },
  { path: '/', name: 'Browser', component: Browser, meta: { requiresAuth: true } },
  { path: '/:pathMatch(.*)*', redirect: '/login' } // Catch-all route
];

const router = createRouter({
  history: createWebHistory(),
  routes,
  base: '/'
});

// Navigation guard to check authentication
router.beforeEach(async (to, from, next) => {
  if (to.meta.requiresAuth) {
    try {
      // Check if user is authenticated by trying to access a protected endpoint
      const response = await fetch('/api/files?path=/');
      if (response.ok) {
        next();
      } else {
        next('/login');
      }
    } catch (error) {
      next('/login');
    }
  } else {
    next();
  }
});

const app = createApp(App);
app.use(router);
app.mount('#app');

