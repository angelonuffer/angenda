const angenda_db = indexedDB.open(location.pathname, 1)
angenda_db.onupgradeneeded = (evento) => {
  const db = evento.target.result
  db.createObjectStore("transações", { keyPath: "id", autoIncrement: true })
}
angenda_db.onsuccess = (evento) => {
  const db = evento.target.result
  ao_criar_db = chamar => chamar(db)
  chamar_ao_criar_db.forEach(ao_criar_db)
}

const chamar_ao_criar_db = []
var ao_criar_db = chamar => { chamar_ao_criar_db.push(chamar) }
const chamar_ao_adicionar = []
const chamar_ao_remover = []

export default {
  adicionar: (coleção, valor) => {
    ao_criar_db(db => db.transaction([coleção], "readwrite").objectStore(coleção).add(valor).onsuccess = evento => {
      const id = evento.target.result
      valor.id = id
      chamar_ao_adicionar.forEach(([coleção2, chamar]) => {
        if (coleção === coleção2) chamar(valor)
      })
    })
  },
  ao_adicionar: (coleção, chamar) => {
    ao_criar_db(db => db.transaction([coleção]).objectStore(coleção).openCursor().onsuccess = evento => {
      const cursor = evento.target.result
      if (cursor) {
        chamar(cursor.value)
        cursor.continue()
      }
    })
    chamar_ao_adicionar.push([coleção, chamar])
  },
  remover: (coleção, id) => {
    ao_criar_db(db => db.transaction([coleção], "readwrite").objectStore(coleção).delete(id).onsuccess = () => {
      chamar_ao_remover.forEach(([coleção2, chamar]) => {
        if (coleção === coleção2) chamar(id)
      })
    })
  },
  ao_remover: (coleção, chamar) => {
    chamar_ao_remover.push([coleção, chamar])
  },
  atualizar: (coleção, valor) => {
    ao_criar_db(db => db.transaction([coleção], "readwrite").objectStore(coleção).put(valor))
  }
}

window.salvar = () => {
  const transações = []
  ao_criar_db(db => db.transaction(["transações"]).objectStore("transações").openCursor().onsuccess = evento => {
    const cursor = evento.target.result
    if (cursor) {
      transações.push(cursor.value)
      cursor.continue()
    } else {
      (async () => {
        const agora = new Date()
        const fileHandle = await window.showSaveFilePicker({suggestedName: [
          agora.getFullYear(),
          (agora.getMonth() + 1).toString().padStart(2, 0),
          agora.getDate().toString().padStart(2, 0),
          agora.getHours(),
          agora.getMinutes(),
          agora.getSeconds(),
        ].join("-") + ".json"})
        const fileStream = await fileHandle.createWritable()
        await fileStream.write(new Blob([JSON.stringify(transações)], {type: "application/json"}))
        await fileStream.close()
      })()
    }
  })
}