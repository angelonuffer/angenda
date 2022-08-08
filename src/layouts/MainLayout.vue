<template>
  <q-layout view="lHh Lpr lFf">
    <q-header elevated>
      <q-toolbar>
        <q-toolbar-title>
          Angenda
        </q-toolbar-title>
      </q-toolbar>
    </q-header>
    <q-page-container>
      <q-page padding>
        <endereço ref="endereço" @ver="$refs.objeto.verId($event)" />
        <objeto ref="objeto" @ver="$refs.endereço.endereço.push($event)" />
      </q-page>
    </q-page-container>
  </q-layout>
</template>

<script>
  import { setCssVar } from 'quasar'
  import Endereço from '../components/Endereço.vue'
  import Objeto from '../components/Objeto.vue'

  setCssVar('primary', '#cd0000')

  export default {
    components: {
      Endereço,
      Objeto,
    },
  }
</script>
