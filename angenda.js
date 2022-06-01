window.onload = () => {
  const div_página = document.querySelector("div#página")
  const div_itens = document.createElement("div")
  div_página.appendChild(div_itens)
  const button = document.createElement("button")
  div_página.appendChild(button)
  const i = document.createElement("i")
  button.appendChild(i)
  i.classList.add("bi-plus-circle")
  button.onclick = () => {
    const div_item = document.createElement("div")
    div_itens.appendChild(div_item)
    div_item.classList.add("item")
    const div_título = document.createElement("div")
    div_item.appendChild(div_título)
    let nome = "Angenda"
    let contador = 1
    while ([...div_itens.children].some(div_item => {
      return div_item.children[0].textContent === nome
    })) {
      nome = "Angenda " + ++contador
    }
    div_título.textContent = nome
    div_item.oncontextmenu = e => {
      e.preventDefault()
      const div = document.createElement("div")
      div_item.appendChild(div)
      div.classList.add("linha")
      const button_eliminar = document.createElement("button")
      div.appendChild(button_eliminar)
      const i_eliminar = document.createElement("i")
      button_eliminar.appendChild(i_eliminar)
      i_eliminar.classList.add("bi-trash")
      button_eliminar.onclick = () => {
        if (confirm("Eliminar \"" + nome + "\"?")) div_itens.removeChild(div_item)
      }
      const button_cancelar = document.createElement("button")
      div.appendChild(button_cancelar)
      const i_cancelar = document.createElement("i")
      button_cancelar.appendChild(i_cancelar)
      i_cancelar.classList.add("bi-x-circle")
      button_cancelar.onclick = () => {
        div_item.removeChild(div)
      }
    }
  }
}
