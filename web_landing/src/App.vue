<script setup>
import { ref, onMounted, onUnmounted } from 'vue';

const currentStep = ref(0);
const steps = [
  { img: '/part1_step1.png', title: '1. Choisissez votre service', desc: 'Sélectionnez le type de dépannage dont vous avez besoin.' },
  { img: '/part1_step2.png', title: '2. Localisez-vous', desc: 'Confirmez votre position exacte sur la carte.' },
  { img: '/part1_step3.png', title: '3. Recherche de pros', desc: 'Visualisez les techniciens qualifiés et disponibles autour de vous.' },
  { img: '/part1_step4.png', title: '4. Détaillez votre demande', desc: 'Expliquez votre panne et ajoutez une photo si besoin.' },
  { img: '/part1_step5.png', title: "5. Le pro reçoit l'offre", desc: 'Votre demande est directement envoyée au meilleur technicien !' },
];

const currentStep2 = ref(0);
const isMapZoomed = ref(true);
const steps2 = [
  { img: '/part1_step4.png', title: '1. Validez la demande', desc: 'Une fois la description complétée, confirmez.' },
  { img: '/part2_step2.png', title: '2. Transmission', desc: "L'application contacte l'artisan en priorité." },
  { img: '/part2_step3.png', title: '3. Mission acceptée', desc: "Le technicien accepte et la mission lui est attribuée." },
  { img: '/part2_step4.png', title: '4. Trajet du Pro', desc: "L'artisan se met en route et est guidé par le GPS intégré." },
  { img: '/part2_step5.png', title: '5. Suivi Client en direct', desc: "Vous suivez son avancée en temps réel jusqu'à votre porte !" },
];

let interval;
let interval2;

onMounted(() => {
  interval = setInterval(() => {
    currentStep.value = (currentStep.value + 1) % steps.length;
  }, 4000);
  interval2 = setInterval(() => {
    currentStep2.value = (currentStep2.value + 1) % steps2.length;
  }, 4000);
});

onUnmounted(() => {
  clearInterval(interval);
  clearInterval(interval2);
});

const setStep = (index) => {
  currentStep.value = index;
  clearInterval(interval);
  interval = setInterval(() => {
    currentStep.value = (currentStep.value + 1) % steps.length;
  }, 4000);
};

const setStep2 = (index) => {
  currentStep2.value = index;
  clearInterval(interval2);
  interval2 = setInterval(() => {
    currentStep2.value = (currentStep2.value + 1) % steps2.length;
  }, 4000);
};
</script>

<template>
  <div class="min-h-screen bg-gray-50 flex flex-col font-sans text-gray-800">
    <!-- Navbar -->
    <header class="bg-white/80 backdrop-blur-md shadow-sm sticky top-0 z-50 border-b border-white/20">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 flex justify-between items-center">
        <div class="flex items-center space-x-3">
          <img src="/logo-client.png" alt="depanGo Logo" class="h-10 w-10 object-contain rounded-xl" />
          <span class="text-2xl font-black text-[#0D776C] tracking-tight">depanGo</span>
        </div>
        <nav class="hidden md:flex space-x-8">
          <a href="#how-it-works" class="text-gray-600 hover:text-[#0D776C] font-medium transition-colors">Comment ça marche</a>
          <a href="#services" class="text-gray-600 hover:text-[#0D776C] font-medium transition-colors">Nos Services</a>
          <a href="#pro" class="text-gray-600 hover:text-[#0D776C] font-medium transition-colors">Devenir Pro</a>
        </nav>
        <div>
          <a href="#download" class="bg-[#0D776C] text-white px-5 py-2.5 rounded-xl font-bold hover:bg-[#095f56] transition-colors shadow-md hover:shadow-lg">
            Commencer
          </a>
        </div>
      </div>
    </header>

    <!-- Hero Section -->
    <section class="flex-grow flex items-center bg-gray-50 py-20 relative overflow-hidden">
      <!-- Background Orbs -->
      <div class="absolute top-0 left-0 w-96 h-96 bg-teal-300 rounded-full mix-blend-multiply filter blur-[128px] opacity-40 "></div>
      <div class="absolute top-0 right-0 w-96 h-96 bg-emerald-300 rounded-full mix-blend-multiply filter blur-[128px] opacity-40 "></div>
      <div class="absolute -bottom-32 left-20 w-96 h-96 bg-cyan-300 rounded-full mix-blend-multiply filter blur-[128px] opacity-40 "></div>

      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 grid md:grid-cols-2 gap-12 items-center">
        <div>
          <h1 class="text-4xl md:text-5xl lg:text-6xl font-extrabold leading-tight text-gray-900 mb-6">
            Votre dépannage express, <span class="text-[#0D776C]">en quelques clics.</span>
          </h1>
          <p class="text-lg text-gray-600 mb-8 max-w-lg">
            Plomberie, électricité, électroménager... Trouvez un technicien certifié près de chez vous en moins de 3 minutes et suivez son arrivée en temps réel !
          </p>
          <div class="flex flex-col sm:flex-row space-y-4 sm:space-y-0 sm:space-x-4 mb-4">
            <a href="#" class="flex items-center justify-center bg-black text-white rounded-xl px-5 py-2.5 hover:bg-gray-800 transition-colors shadow-lg border border-gray-700">
              <img src="/app-store.png" alt="App Store" class="h-8 mr-3 object-contain" />
              <div class="text-left">
                <div class="text-[10px] leading-tight text-gray-300">Télécharger dans l'</div>
                <div class="text-base font-semibold leading-tight">App Store</div>
              </div>
            </a>
            <a href="#" class="flex items-center justify-center bg-black text-white rounded-xl px-5 py-2.5 hover:bg-gray-800 transition-colors shadow-lg border border-gray-700">
              <img src="/play-store.png" alt="Google Play" class="h-8 mr-3 object-contain" />
              <div class="text-left">
                <div class="text-[10px] leading-tight text-gray-300">DISPONIBLE SUR</div>
                <div class="text-base font-semibold leading-tight">Google Play</div>
              </div>
            </a>
          </div>
          <a href="#pro" class="inline-flex items-center text-[#0D776C] font-semibold hover:underline group mt-4">
            <svg class="w-5 h-5 mr-2 group-hover:scale-110 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2m4 6h.01M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path></svg>
            Vous êtes un technicien ? Découvrez l'Espace Pro ➔
          </a>
          
          <div class="mt-10 flex items-center space-x-4 text-sm text-gray-500 font-medium">
            <div class="flex -space-x-3">
               <img src="https://i.pravatar.cc/100?img=1" class="w-10 h-10 rounded-full border-2 border-white object-cover shadow-sm" />
               <img src="https://i.pravatar.cc/100?img=2" class="w-10 h-10 rounded-full border-2 border-white object-cover shadow-sm" />
               <img src="https://i.pravatar.cc/100?img=3" class="w-10 h-10 rounded-full border-2 border-white object-cover shadow-sm" />
            </div>
            <span class="pl-2">+10 000 utilisateurs satisfaits</span>
          </div>
        </div>
        
        <div class="relative flex justify-center">
          <div class="absolute inset-0 bg-[#0D776C] rounded-full blur-3xl opacity-20 transform scale-150"></div>
          <img src="/app-client-screen.png" alt="App Client Preview" class="relative z-10 w-full max-w-[280px] drop-shadow-2xl rounded-[2.5rem] border-[8px] border-gray-900 mx-auto object-cover object-top aspect-[9/19.5]" />
        </div>
      </div>
    </section>

    <!-- How it works (Carousel 1) -->
    <section id="how-it-works" class="py-24 bg-white border-t border-gray-100">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-16">
          <div class="text-[#0D776C] font-bold tracking-wide uppercase text-sm mb-3">Simple et Rapide</div>
          <h2 class="text-3xl md:text-4xl font-extrabold text-gray-900 mb-4">Comment ça marche ?</h2>
          <p class="text-gray-600 max-w-2xl mx-auto text-lg">Commandez votre dépannage en 5 étapes ultra-simples, sans tracas.</p>
        </div>
        
        <div class="flex flex-col md:flex-row items-center gap-12 lg:gap-24">
          <!-- Phone mockup -->
          <div class="md:w-1/2 flex justify-center">
             <div class="relative inline-block">
               <div v-for="(step, index) in steps" :key="index" 
                    class="transition-opacity duration-700 ease-in-out absolute inset-0"
                    :class="index === currentStep ? 'opacity-100 z-20' : 'opacity-0 z-10'">
                 <img :src="step.img" :alt="step.title" class="w-full max-w-[280px] rounded-[2.5rem] shadow-2xl border-[8px] border-gray-900 mx-auto object-cover object-top aspect-[9/19.5]" />
               </div>
               <!-- Base invisible image -->
               <img :src="steps[0].img" class="w-full max-w-[280px] rounded-[2.5rem] border-[8px] border-transparent invisible aspect-[9/19.5]" />
             </div>
          </div>
          
          <!-- Steps list -->
          <div class="md:w-1/2 w-full max-w-lg">
            <div class="space-y-4">
              <div v-for="(step, index) in steps" :key="index" 
                   @click="setStep(index)"
                   class="p-5 rounded-2xl cursor-pointer transition-all duration-300 border-2"
                   :class="index === currentStep ? 'border-[#0D776C] bg-teal-50 shadow-md transform scale-105' : 'border-transparent hover:bg-gray-50'">
                <h3 class="text-xl font-bold mb-1" :class="index === currentStep ? 'text-[#0D776C]' : 'text-gray-700'">{{ step.title }}</h3>
                <p class="text-gray-500 text-sm leading-relaxed" v-show="index === currentStep">{{ step.desc }}</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- How it works Part 2 (Carousel 2) -->
    <section class="py-24 bg-gray-50 border-t border-gray-100">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-16">
          <div class="text-[#0D776C] font-bold tracking-wide uppercase text-sm mb-3">La magie opère</div>
          <h2 class="text-3xl md:text-4xl font-extrabold text-gray-900 mb-4">De la commande à l'intervention</h2>
          <p class="text-gray-600 max-w-2xl mx-auto text-lg">Découvrez comment l'application connecte instantanément les clients et les pros.</p>
        </div>
        
        <div class="flex flex-col md:flex-row items-center gap-12 lg:gap-24">
          <!-- Steps list (Left side) -->
          <div class="md:w-1/2 w-full max-w-lg order-2 md:order-1">
            <div class="mb-8">
              <h3 class="text-2xl font-bold text-gray-900 mb-2">Suivi et Prise en charge</h3>
              <p class="text-gray-600">Voyez exactement ce qu'il se passe de la validation jusqu'à l'arrivée de l'artisan.</p>
            </div>
            <div class="space-y-4">
              <div v-for="(step, index) in steps2" :key="index" 
                   @click="setStep2(index)"
                   class="p-5 rounded-2xl cursor-pointer transition-all duration-300 border-2"
                   :class="index === currentStep2 ? 'border-[#0D776C] bg-white shadow-md transform scale-105' : 'border-transparent hover:bg-gray-200/50'">
                <h3 class="text-xl font-bold mb-1" :class="index === currentStep2 ? 'text-[#0D776C]' : 'text-gray-700'">{{ step.title }}</h3>
                <p class="text-gray-500 text-sm leading-relaxed" v-show="index === currentStep2">{{ step.desc }}</p>
              </div>
            </div>
          </div>
          
          <!-- Phone mockup (Right side) -->
          <div class="md:w-1/2 flex justify-center order-1 md:order-2">
             <div class="relative inline-block">
               <div v-for="(step, index) in steps2" :key="index" 
                    class="transition-opacity duration-700 ease-in-out absolute inset-0"
                    :class="index === currentStep2 ? 'opacity-100 z-20' : 'opacity-0 z-10'">
                 <img :src="step.img" :alt="step.title" class="w-full max-w-[280px] rounded-[2.5rem] shadow-2xl border-[8px] border-gray-900 mx-auto object-cover object-top aspect-[9/19.5]" />
               </div>
               <!-- Base invisible image -->
               <img :src="steps2[0].img" class="w-full max-w-[280px] rounded-[2.5rem] border-[8px] border-transparent invisible aspect-[9/19.5]" />
             </div>
          </div>
        </div>
      </div>
    </section>


    <!-- Location Feature Section -->
    <section class="py-24 bg-white border-t border-gray-100 relative overflow-hidden">
      <!-- Orbs -->
      <div class="absolute inset-0 z-0 pointer-events-none">
        <div class="absolute top-1/2 left-0 w-96 h-96 bg-teal-100 rounded-full mix-blend-multiply filter blur-[120px] opacity-60 -translate-y-1/2"></div>
      </div>
      
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 grid md:grid-cols-2 gap-16 items-center relative z-10">
        <!-- Text side -->
        <div class="order-1">
          <div class="text-[#0D776C] font-bold tracking-wide uppercase text-sm mb-3">Précision & Rapidité</div>
          <h2 class="text-3xl md:text-5xl font-extrabold text-gray-900 mb-6 leading-tight">
            Définir votre position <br/>en toute simplicité 😎
          </h2>
          <p class="text-gray-600 text-lg leading-relaxed mb-8">
            Plus besoin de saisir de longues adresses compliquées ! L'application détecte instantanément où vous vous trouvez avec une précision redoutable pour vous trouver de l'aide au plus vite.
          </p>
          <ul class="space-y-5">
            <li class="flex items-start bg-gray-50/80 backdrop-blur-sm p-4 rounded-2xl border border-gray-100 shadow-sm">
              <div class="flex-shrink-0 w-8 h-8 rounded-full bg-teal-50 flex items-center justify-center mr-4">
                <svg class="w-5 h-5 text-[#0D776C]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7"></path></svg>
              </div>
              <span class="text-gray-800 font-medium self-center">Aperçu direct depuis la page d'accueil</span>
            </li>
            <li class="flex items-start bg-gray-50/80 backdrop-blur-sm p-4 rounded-2xl border border-gray-100 shadow-sm">
              <div class="flex-shrink-0 w-8 h-8 rounded-full bg-teal-50 flex items-center justify-center mr-4">
                <svg class="w-5 h-5 text-[#0D776C]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7"></path></svg>
              </div>
              <span class="text-gray-800 font-medium self-center">Ajustement fluide sur la carte Google Maps</span>
            </li>
          </ul>
        </div>
        
        <!-- Images side (overlapping) -->
        <div class="order-2 relative flex justify-center items-center h-[550px] w-full">
          <!-- Background Image (Offset right) -->
          <img src="/location_full.png" class="absolute right-4 md:right-8 top-12 w-full max-w-[240px] rounded-[2.5rem] shadow-2xl border-[6px] border-gray-900 object-cover object-top aspect-[9/19.5] rotate-6 transform opacity-90 hover:opacity-100 hover:rotate-0 hover:z-20 transition-all duration-500 cursor-pointer" alt="Carte Plein Ecran" />
          
          <!-- Foreground Image (Offset left) -->
          <img src="/location_preview.png" class="absolute left-4 md:left-8 top-0 w-full max-w-[260px] rounded-[2.5rem] shadow-[0_20px_50px_rgba(0,0,0,0.3)] border-[8px] border-gray-900 object-cover object-top aspect-[9/19.5] -rotate-3 transform hover:rotate-0 transition-all duration-500 z-10 cursor-pointer" alt="Apercu Accueil" />
        </div>
      </div>
    </section>

    <!-- Services Section -->
    <section id="services" class="py-24 bg-gray-50 border-t border-gray-100 relative overflow-hidden">
      <!-- Background Orbs -->
      <div class="absolute inset-0 z-0">
        <div class="absolute top-1/4 left-1/4 w-64 h-64 bg-blue-200 rounded-full mix-blend-multiply filter blur-[100px] opacity-50"></div>
        <div class="absolute bottom-1/4 right-1/4 w-64 h-64 bg-amber-200 rounded-full mix-blend-multiply filter blur-[100px] opacity-50"></div>
      </div>
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-16">
          <h2 class="text-3xl font-bold text-gray-900 mb-4">Tous les services à portée de main</h2>
          <p class="text-gray-600 max-w-2xl mx-auto">Un problème urgent ? Nous avons le professionnel qu'il vous faut, vérifié et prêt à intervenir.</p>
        </div>
        
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-8">
          <div class="bg-white/60 backdrop-blur-xl border border-white shadow-xl rounded-2xl p-6 text-center relative z-10 hover:-translate-y-2 transition-transform duration-300">
            <div class="w-16 h-16 mx-auto bg-blue-100 text-blue-600 rounded-full flex items-center justify-center mb-4">
              <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"></path></svg>
            </div>
            <h3 class="text-xl font-bold mb-2">Plomberie</h3>
            <p class="text-gray-600 text-sm">Fuites, débouchage, installation sanitaire.</p>
          </div>
          <div class="bg-white/60 backdrop-blur-xl border border-white shadow-xl rounded-2xl p-6 text-center relative z-10 hover:-translate-y-2 transition-transform duration-300">
            <div class="w-16 h-16 mx-auto bg-amber-100 text-amber-600 rounded-full flex items-center justify-center mb-4">
              <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path></svg>
            </div>
            <h3 class="text-xl font-bold mb-2">Électricité</h3>
            <p class="text-gray-600 text-sm">Coupure, installation, tableau électrique.</p>
          </div>
          <div class="bg-white/60 backdrop-blur-xl border border-white shadow-xl rounded-2xl p-6 text-center relative z-10 hover:-translate-y-2 transition-transform duration-300">
            <div class="w-16 h-16 mx-auto bg-cyan-100 text-cyan-600 rounded-full flex items-center justify-center mb-4">
              <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 10l-2 1m0 0l-2-1m2 1v2.5M20 7l-2 1m2-1l-2-1m2 1v2.5M14 4l-2-1-2 1M4 7l2-1M4 7l2 1M4 7v2.5M12 21l-2-1m2 1l2-1m-2 1v-2.5M6 18l-2-1v-2.5M18 18l2-1v-2.5"></path></svg>
            </div>
            <h3 class="text-xl font-bold mb-2">Climatisation</h3>
            <p class="text-gray-600 text-sm">Entretien, réparation, recharge de gaz.</p>
          </div>
          <div class="bg-white/60 backdrop-blur-xl border border-white shadow-xl rounded-2xl p-6 text-center relative z-10 hover:-translate-y-2 transition-transform duration-300">
            <div class="w-16 h-16 mx-auto bg-purple-100 text-purple-600 rounded-full flex items-center justify-center mb-4">
              <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z"></path></svg>
            </div>
            <h3 class="text-xl font-bold mb-2">Électroménager</h3>
            <p class="text-gray-600 text-sm">Réparation frigo, machine à laver, four.</p>
          </div>
        </div>
      </div>
    </section>


    <!-- Active Zones / Global Map Section -->
    <section class="py-24 bg-gray-50 border-t border-gray-100 relative overflow-hidden">
      <!-- Background Orbs -->
      <div class="absolute inset-0 z-0">
        <div class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-teal-200/30 rounded-full mix-blend-multiply filter blur-[150px]"></div>
      </div>
      
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10 text-center">
        <div class="text-[#0D776C] font-bold tracking-wide uppercase text-sm mb-3">Couverture Mondiale</div>
        <h2 class="text-3xl md:text-5xl font-extrabold text-gray-900 mb-6 leading-tight">
          Nos zones les <br/>plus actives 🌍
        </h2>
        <p class="text-gray-600 text-lg max-w-2xl mx-auto mb-16">
          Une communauté internationale grandissante. Découvrez en temps réel où nos professionnels interviennent le plus pour sauver la journée !
        </p>
        
        <!-- Interactive Map Container -->
        <div class="relative w-full max-w-5xl mx-auto h-[400px] md:h-[500px] bg-white/60 backdrop-blur-xl border border-white rounded-[3rem] shadow-2xl overflow-hidden flex items-center justify-center">
          
          <!-- Real World Map SVG -->
          <img src="/world_map.svg" class="absolute inset-0 w-full h-full object-contain opacity-20 invert" alt="World Map" style="filter: invert(36%) sepia(93%) saturate(415%) hue-rotate(124deg) brightness(90%) contrast(85%);" />
          
          <!-- Subtle Grid Overlay for tech feel -->
          <div class="absolute inset-0 opacity-[0.03]" style="background-image: radial-gradient(#000 2px, transparent 2px); background-size: 20px 20px;"></div>

          <!-- Pulsing Dots (Active Zones) -->
          
          <!-- Senegal / Dakar -->
          <div class="absolute top-[55%] left-[46%] z-20">
            <div class="relative flex h-8 w-8">
              <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-teal-400 opacity-75"></span>
              <span class="relative inline-flex rounded-full h-8 w-8 bg-[#0D776C] border-2 border-white shadow-lg"></span>
            </div>
            <div class="absolute top-10 -left-6 bg-white px-3 py-1 rounded-lg shadow-md border border-gray-100 text-xs font-bold text-gray-800 whitespace-nowrap">
              Dakar, Sénégal (Zone Active)
            </div>
          </div>
          
          <!-- Central Badge -->
          <div class="relative z-10 bg-white/90 backdrop-blur-md px-6 py-4 rounded-2xl shadow-xl border border-gray-100 flex items-center space-x-4 mt-auto mb-6">
            <div class="w-12 h-12 bg-teal-50 rounded-full flex items-center justify-center text-[#0D776C]">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 104 0 2 2 0 012-2h1.064M15 20.488V18a2 2 0 012-2h3.064M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
            </div>
            <div class="text-left">
              <div class="font-black text-xl text-gray-900">Hub Principal</div>
              <div class="text-sm text-gray-500 font-medium">Déploiement international à venir</div>
            </div>
          </div>
          
        </div>
      </div>
    </section>

    <!-- Features Section -->
    <section id="features" class="py-24 bg-gray-50 border-t border-gray-100 relative overflow-hidden">
      <!-- Background Orbs -->
      <div class="absolute inset-0 z-0">
        <div class="absolute top-0 right-1/4 w-80 h-80 bg-teal-200 rounded-full mix-blend-multiply filter blur-[120px] opacity-50"></div>
        <div class="absolute bottom-0 left-1/4 w-80 h-80 bg-purple-200 rounded-full mix-blend-multiply filter blur-[120px] opacity-50"></div>
      </div>
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-16">
          <div class="text-[#0D776C] font-bold tracking-wide uppercase text-sm mb-3">Pourquoi choisir depanGo ?</div>
          <h2 class="text-3xl md:text-4xl font-extrabold text-gray-900 mb-4">Best Features <br/><span class="text-[#0D776C]">We Offer for You</span></h2>
          <p class="text-gray-600 max-w-2xl mx-auto text-lg">Nous avons repensé le dépannage à domicile pour vous offrir la meilleure expérience possible.</p>
        </div>
        
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-10">
          <div class="bg-white/60 backdrop-blur-xl p-8 rounded-3xl shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-white relative z-10 hover:shadow-xl transition-shadow duration-300">
            <div class="w-14 h-14 bg-teal-50 text-teal-600 rounded-2xl flex items-center justify-center mb-6 shadow-inner border border-teal-100">
              <svg class="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path></svg>
            </div>
            <h3 class="text-xl font-bold mb-3 text-gray-900">Intervention Express</h3>
            <p class="text-gray-600 leading-relaxed">Notre algorithme trouve le technicien disponible le plus proche de vous en moins de 3 minutes.</p>
          </div>
          <div class="bg-white/60 backdrop-blur-xl p-8 rounded-3xl shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-white relative z-10 hover:shadow-xl transition-shadow duration-300">
            <div class="w-14 h-14 bg-blue-50 text-blue-600 rounded-2xl flex items-center justify-center mb-6 shadow-inner border border-blue-100">
              <svg class="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.243-4.243a8 8 0 1111.314 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>
            </div>
            <h3 class="text-xl font-bold mb-3 text-gray-900">Suivi GPS en Direct</h3>
            <p class="text-gray-600 leading-relaxed">Fini l'attente incertaine. Suivez le trajet de votre technicien sur la carte jusqu'à votre porte.</p>
          </div>
          <div class="bg-white/60 backdrop-blur-xl p-8 rounded-3xl shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-white relative z-10 hover:shadow-xl transition-shadow duration-300">
            <div class="w-14 h-14 bg-amber-50 text-amber-600 rounded-2xl flex items-center justify-center mb-6 shadow-inner border border-amber-100">
              <svg class="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z"></path></svg>
            </div>
            <h3 class="text-xl font-bold mb-3 text-gray-900">Techniciens Vérifiés</h3>
            <p class="text-gray-600 leading-relaxed">Chaque professionnel est rigoureusement sélectionné, évalué par la communauté et certifié.</p>
          </div>
          <div class="bg-white/60 backdrop-blur-xl p-8 rounded-3xl shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-white relative z-10 hover:shadow-xl transition-shadow duration-300">
            <div class="w-14 h-14 bg-purple-50 text-purple-600 rounded-2xl flex items-center justify-center mb-6 shadow-inner border border-purple-100">
              <svg class="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"></path></svg>
            </div>
            <h3 class="text-xl font-bold mb-3 text-gray-900">Garantie Qualité</h3>
            <p class="text-gray-600 leading-relaxed">Une intervention sécurisée et une équipe support toujours disponible en cas de problème.</p>
          </div>
          <div class="bg-white/60 backdrop-blur-xl p-8 rounded-3xl shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-white relative z-10 hover:shadow-xl transition-shadow duration-300">
            <div class="w-14 h-14 bg-rose-50 text-rose-600 rounded-2xl flex items-center justify-center mb-6 shadow-inner border border-rose-100">
              <svg class="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"></path></svg>
            </div>
            <h3 class="text-xl font-bold mb-3 text-gray-900">Paiement Transparent</h3>
            <p class="text-gray-600 leading-relaxed">Payez en espèces ou via Mobile Money de façon sécurisée une fois le travail terminé.</p>
          </div>
          <div class="bg-[#0D776C]/90 backdrop-blur-xl p-8 rounded-3xl shadow-lg border border-teal-500/30 relative z-10 hover:shadow-xl transition-shadow duration-300 text-white flex flex-col justify-center items-center text-center relative overflow-hidden">
            <div class="absolute -top-10 -right-10 w-40 h-40 bg-teal-500 rounded-full mix-blend-multiply filter blur-2xl opacity-50"></div>
            <div class="absolute -bottom-10 -left-10 w-40 h-40 bg-teal-800 rounded-full mix-blend-multiply filter blur-2xl opacity-50"></div>
            <h3 class="text-2xl font-bold mb-4 z-10">Prêt à essayer ?</h3>
            <p class="text-teal-100 mb-6 z-10">Téléchargez l'application et réservez votre premier dépannage aujourd'hui.</p>
            <a href="#download" class="bg-white text-[#0D776C] font-bold px-6 py-3 rounded-xl hover:bg-teal-50 transition-colors w-full z-10 shadow-lg">C'est parti !</a>
          </div>
        </div>
      </div>
    </section>

    <!-- Pro Section (Modernized) -->
    <section id="pro" class="py-32 relative overflow-hidden bg-white border-t border-gray-100">
      <!-- Background Orbs (Light theme to match the rest) -->
      <div class="absolute inset-0 z-0">
        <div class="absolute top-0 right-0 w-96 h-96 bg-teal-200 rounded-full mix-blend-multiply filter blur-[120px] opacity-40 -translate-y-1/2 translate-x-1/3"></div>
        <div class="absolute bottom-0 left-0 w-96 h-96 bg-emerald-200 rounded-full mix-blend-multiply filter blur-[120px] opacity-40 translate-y-1/3 -translate-x-1/3"></div>
      </div>
      
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 grid md:grid-cols-2 gap-16 items-center relative z-10">
        <div class="order-2 md:order-1 flex justify-center relative">
           <div class="relative inline-block transform transition-transform hover:scale-105 duration-500">
             <img src="/app-pro-screen.png" alt="App Pro Preview" class="w-full max-w-[280px] rounded-[3rem] shadow-2xl border-[8px] border-gray-900 mx-auto object-cover object-top aspect-[9/19.5]" />
             
             <!-- Glassmorphism card (Light) -->
             <div class="absolute -bottom-6 -right-6 md:-right-10 bg-white/80 backdrop-blur-xl border border-white p-5 rounded-2xl shadow-xl z-30 transform hover:-translate-y-2 transition-transform duration-300">
               <div class="flex items-center space-x-3 mb-1">
                 <div class="w-10 h-10 bg-[#0D776C] rounded-full flex items-center justify-center shadow-lg">
                   <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                 </div>
                 <div>
                   <div class="font-black text-2xl tracking-tight text-gray-900">+40%</div>
                   <div class="text-xs text-gray-500 font-bold">De revenus moyens</div>
                 </div>
               </div>
             </div>
           </div>
        </div>
        
        <div class="order-1 md:order-2">
          <div class="inline-flex items-center space-x-2 bg-teal-50 text-[#0D776C] px-4 py-2 rounded-full text-sm font-bold mb-6 border border-teal-100 shadow-sm">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2m4 6h.01M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path></svg>
            <span>Pour les Techniciens</span>
          </div>
          <h2 class="text-3xl md:text-5xl font-extrabold mb-6 leading-tight text-gray-900">
            Devenez partenaire <br/><span class="text-[#0D776C]">depanGo Pro</span>
          </h2>
          <p class="text-gray-600 mb-8 text-lg leading-relaxed">
            Rejoignez notre réseau exclusif de professionnels. Recevez des missions géolocalisées, gérez votre emploi du temps depuis votre mobile et augmentez vos revenus en toute liberté.
          </p>
          
          <ul class="space-y-5 mb-12">
            <li class="flex items-start bg-white/60 backdrop-blur-md p-4 rounded-2xl border border-white shadow-sm">
              <div class="flex-shrink-0 w-8 h-8 rounded-full bg-teal-50 flex items-center justify-center mr-4 shadow-inner border border-teal-100">
                <svg class="w-5 h-5 text-[#0D776C]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7"></path></svg>
              </div>
              <span class="text-gray-700 font-medium self-center">Inscription gratuite et 100% digitale</span>
            </li>
            <li class="flex items-start bg-white/60 backdrop-blur-md p-4 rounded-2xl border border-white shadow-sm">
              <div class="flex-shrink-0 w-8 h-8 rounded-full bg-teal-50 flex items-center justify-center mr-4 shadow-inner border border-teal-100">
                <svg class="w-5 h-5 text-[#0D776C]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7"></path></svg>
              </div>
              <span class="text-gray-700 font-medium self-center">Paiements sécurisés garantis à chaque mission</span>
            </li>
            <li class="flex items-start bg-white/60 backdrop-blur-md p-4 rounded-2xl border border-white shadow-sm">
              <div class="flex-shrink-0 w-8 h-8 rounded-full bg-teal-50 flex items-center justify-center mr-4 shadow-inner border border-teal-100">
                <svg class="w-5 h-5 text-[#0D776C]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7"></path></svg>
              </div>
              <span class="text-gray-700 font-medium self-center">Flexibilité totale de vos horaires de travail</span>
            </li>
          </ul>
          
          <div class="flex flex-col sm:flex-row space-y-4 sm:space-y-0 sm:space-x-4">
            <a href="#" class="flex items-center justify-center bg-black text-white rounded-xl px-5 py-2.5 hover:bg-gray-800 transition-colors shadow-xl border border-gray-700 hover:scale-105 duration-300">
              <img src="/app-store.png" alt="App Store" class="h-8 mr-3 object-contain" />
              <div class="text-left">
                <div class="text-[10px] leading-tight text-gray-300">Télécharger dans l'</div>
                <div class="text-base font-semibold leading-tight">App Store</div>
              </div>
            </a>
            <a href="#" class="flex items-center justify-center bg-black text-white rounded-xl px-5 py-2.5 hover:bg-gray-800 transition-colors shadow-xl border border-gray-700 hover:scale-105 duration-300">
              <img src="/play-store.png" alt="Google Play" class="h-8 mr-3 object-contain" />
              <div class="text-left">
                <div class="text-[10px] leading-tight text-gray-300">DISPONIBLE SUR</div>
                <div class="text-base font-semibold leading-tight">Google Play</div>
              </div>
            </a>
          </div>
        </div>
      </div>
    </section>
<!-- Footer with Contact & Socials -->
    <footer class="bg-slate-50 pt-16 pb-8 border-t border-slate-200 shadow-[inset_0_1px_3px_rgba(0,0,0,0.02)] relative overflow-hidden">
      <!-- Footer subtle accent -->
      <div class="absolute top-0 left-1/2 -translate-x-1/2 w-3/4 h-1 bg-gradient-to-r from-transparent via-[#0D776C]/20 to-transparent"></div>
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="grid grid-cols-1 md:grid-cols-4 gap-12 mb-16">
          
          <div class="col-span-1 md:col-span-2">
            <div class="flex items-center space-x-3 mb-6">
              <img src="/logo-client.png" alt="depanGo Logo" class="h-10 w-10 object-contain rounded-xl grayscale opacity-70" />
              <span class="text-2xl font-black text-gray-800 tracking-tight">depanGo</span>
            </div>
            <p class="text-gray-500 mb-6 max-w-sm leading-relaxed">
              La plateforme numéro 1 de mise en relation entre particuliers et professionnels du dépannage à domicile.
            </p>
            <div class="flex space-x-4">
              <!-- Facebook -->
              <a href="#" class="w-10 h-10 rounded-xl bg-white border border-gray-100 shadow-sm flex items-center justify-center text-gray-500 hover:bg-[#0D776C] hover:text-white transition-all">
                <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M22 12c0-5.523-4.477-10-10-10S2 6.477 2 12c0 4.991 3.657 9.128 8.438 9.878v-6.987h-2.54V12h2.54V9.797c0-2.506 1.492-3.89 3.777-3.89 1.094 0 2.238.195 2.238.195v2.46h-1.26c-1.243 0-1.63.771-1.63 1.562V12h2.773l-.443 2.89h-2.33v6.988C18.343 21.128 22 16.991 22 12z"/></svg>
              </a>
              <!-- Instagram -->
              <a href="#" class="w-10 h-10 rounded-xl bg-white border border-gray-100 shadow-sm flex items-center justify-center text-gray-500 hover:bg-[#0D776C] hover:text-white transition-all">
                <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path fill-rule="evenodd" d="M12.315 2c2.43 0 2.784.013 3.808.06 1.064.049 1.791.218 2.427.465a4.902 4.902 0 011.772 1.153 4.902 4.902 0 011.153 1.772c.247.636.416 1.363.465 2.427.048 1.067.06 1.407.06 4.123v.08c0 2.643-.012 2.987-.06 4.043-.049 1.064-.218 1.791-.465 2.427a4.902 4.902 0 01-1.153 1.772 4.902 4.902 0 01-1.772 1.153c-.636.247-1.363.416-2.427.465-1.067.048-1.407.06-4.123.06h-.08c-2.643 0-2.987-.012-4.043-.06-1.064-.049-1.791-.218-2.427-.465a4.902 4.902 0 01-1.772-1.153 4.902 4.902 0 01-1.153-1.772c-.247-.636-.416-1.363-.465-2.427-.047-1.024-.06-1.379-.06-3.808v-.63c0-2.43.013-2.784.06-3.808.049-1.064.218-1.791.465-2.427a4.902 4.902 0 011.153-1.772A4.902 4.902 0 015.45 2.525c.636-.247 1.363-.416 2.427-.465C8.901 2.013 9.256 2 11.685 2h.63zm-.081 1.802h-.468c-2.456 0-2.784.011-3.807.058-.975.045-1.504.207-1.857.344-.467.182-.8.398-1.15.748-.35.35-.566.683-.748 1.15-.137.353-.3.882-.344 1.857-.047 1.023-.058 1.351-.058 3.807v.468c0 2.456.011 2.784.058 3.807.045.975.207 1.504.344 1.857.182.466.399.8.748 1.15.35.35.683.566 1.15.748.353.137.882.3 1.857.344 1.054.048 1.37.058 4.041.058h.08c2.597 0 2.917-.01 3.96-.058.976-.045 1.505-.207 1.858-.344.466-.182.8-.398 1.15-.748.35-.35.566-.683.748-1.15.137-.353.3-.882.344-1.857.048-1.055.058-1.37.058-4.041v-.08c0-2.597-.01-2.917-.058-3.96-.045-.976-.207-1.505-.344-1.858a3.097 3.097 0 00-.748-1.15 3.098 3.098 0 00-1.15-.748c-.353-.137-.882-.3-1.857-.344-1.023-.047-1.351-.058-3.807-.058zM12 6.865a5.135 5.135 0 110 10.27 5.135 5.135 0 010-10.27zm0 1.802a3.333 3.333 0 100 6.666 3.333 3.333 0 000-6.666zm5.338-3.205a1.2 1.2 0 110 2.4 1.2 1.2 0 010-2.4z" clip-rule="evenodd"/></svg>
              </a>
              <!-- LinkedIn -->
              <a href="#" class="w-10 h-10 rounded-xl bg-white border border-gray-100 shadow-sm flex items-center justify-center text-gray-500 hover:bg-[#0D776C] hover:text-white transition-all">
                <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path fill-rule="evenodd" d="M19 0h-14c-2.761 0-5 2.239-5 5v14c0 2.761 2.239 5 5 5h14c2.762 0 5-2.239 5-5v-14c0-2.761-2.238-5-5-5zm-11 19h-3v-11h3v11zm-1.5-12.268c-.966 0-1.75-.79-1.75-1.764s.784-1.764 1.75-1.764 1.75.79 1.75 1.764-.783 1.764-1.75 1.764zm13.5 12.268h-3v-5.604c0-3.368-4-3.113-4 0v5.604h-3v-11h3v1.765c1.396-2.586 7-2.777 7 2.476v6.759z" clip-rule="evenodd"/></svg>
              </a>
            </div>
          </div>
          
          <div>
            <h4 class="font-bold text-gray-900 mb-6 uppercase tracking-wider text-sm">Entreprise</h4>
            <ul class="space-y-4">
              <li><a href="#" class="text-gray-500 hover:text-[#0D776C] transition-colors">À propos de nous</a></li>
              <li><a href="#" class="text-gray-500 hover:text-[#0D776C] transition-colors">Devenir Partenaire Pro</a></li>
              <li><a href="#" class="text-gray-500 hover:text-[#0D776C] transition-colors">Carrières</a></li>
              <li><a href="#" class="text-gray-500 hover:text-[#0D776C] transition-colors">Blog</a></li>
            </ul>
          </div>
          
          <div>
            <h4 class="font-bold text-gray-900 mb-6 uppercase tracking-wider text-sm">Contactez-nous</h4>
            <ul class="space-y-4">
              <li class="flex items-start space-x-3 text-gray-500">
                <svg class="w-5 h-5 text-[#0D776C] mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path></svg>
                <a href="mailto:contact@depango.sn" class="hover:text-[#0D776C] transition-colors">contact@depango.sn</a>
              </li>
              <li class="flex items-start space-x-3 text-gray-500">
                <svg class="w-5 h-5 text-[#0D776C] mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"></path></svg>
                <a href="tel:+221770000000" class="hover:text-[#0D776C] transition-colors">+221 77 000 00 00</a>
              </li>
              <li class="flex items-start space-x-3 text-gray-500">
                <svg class="w-5 h-5 text-[#0D776C] mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.243-4.243a8 8 0 1111.314 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>
                <span>Service International</span>
              </li>
            </ul>
          </div>
          
        </div>
        
        <div class="border-t border-gray-100 pt-8 flex flex-col md:flex-row justify-between items-center text-sm text-gray-400">
          <p>© 2026 depanGo. Tous droits réservés.</p>
          <div class="mt-4 md:mt-0 space-x-6">
            <a href="#" class="hover:text-[#0D776C] transition-colors">Conditions d'utilisation</a>
            <a href="#" class="hover:text-[#0D776C] transition-colors">Politique de confidentialité</a>
          </div>
        </div>
      </div>
    </footer>
  </div>
</template>

<!-- trigger hmr -->
