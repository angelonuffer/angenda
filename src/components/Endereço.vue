<template>
  <span>
    <template v-for="(objeto, i) in endereço">
      <q-icon name="arrow_right" v-if="i > 0" />
      <q-btn :icon="objeto.ícone" no-caps @click="ver(i)">{{ objeto.nome }}</q-btn>
    </template>
  </span>
</template>

<style scoped>
  span {
    display: flex;
    flex-direction: row;
    overflow-x: scroll;
    align-items: center;
  }
</style>

<script>
  export default {
    data() {
      return {
        endereço: [{ ícone: 'home', id: 0 }],
      }
    },
    methods: {
      ver(i) {
        this.endereço.splice(i + 1)
        this.$emit('ver', this.endereço[i].id)
      },
    },
  }
</script>
