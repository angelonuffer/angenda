export const ícones = {
  Object: 'emoji_objects',
  Array: 'list',
  String: 'abc',
  Number: '123',
  Boolean: 'toggle_on',
}

export const nomes = {
  Object: 'Objeto',
  Array: 'Lista',
  String: 'Texto',
  Number: 'Número',
  Boolean: 'Lógico',
}

export let objetoAtual = {id: 0}

export let obter
export let modificar
export let deletar
export let iniciado = new Promise(resolver => {
  const r = indexedDB.open(location.pathname, 1)
  r.onupgradeneeded = e => {
    const db = e.target.result
    const objetos = db.createObjectStore('objetos', { autoIncrement: true })
    objetos.add({}, 0)
  }
  r.onsuccess = e => {
    const db = e.target.result
    obter = (id) => {
      return new Promise(resolver => {
        const objetos = db.transaction(['objetos'], 'readwrite').objectStore('objetos')
        objetos.get(id).onsuccess = e => resolver(e.target.result)
      })
    }
    modificar = (nome, valor) => {
      return new Promise(resolver => {
        obter(objetoAtual.id).then(objeto => {
          const objetos = db.transaction(['objetos'], 'readwrite').objectStore('objetos')
          if (valor.constructor === Object) {
            objetos.add({}).onsuccess = e => {
              objeto[nome] = {id: e.target.result}
              objetos.put(objeto, objetoAtual.id)
              resolver(e.target.result)
            }
            return
          }
          objeto[nome] = valor
          objetos.put(objeto, objetoAtual.id)
        })
      })
    }
    deletar = chave => {
      obter(objetoAtual.id).then(objeto => {
        const objetos = db.transaction(['objetos'], 'readwrite').objectStore('objetos')
        if (objeto[chave].constructor === Object) objetos.delete(objeto[chave].id)
        delete objeto[chave]
        objetos.put(objeto, objetoAtual.id)
      })
    }
    resolver()
  }
})
