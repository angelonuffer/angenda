(function(t){function e(e){for(var n,i,o=e[0],c=e[1],d=e[2],l=0,m=[];l<o.length;l++)i=o[l],Object.prototype.hasOwnProperty.call(r,i)&&r[i]&&m.push(r[i][0]),r[i]=0;for(n in c)Object.prototype.hasOwnProperty.call(c,n)&&(t[n]=c[n]);u&&u(e);while(m.length)m.shift()();return s.push.apply(s,d||[]),a()}function a(){for(var t,e=0;e<s.length;e++){for(var a=s[e],n=!0,o=1;o<a.length;o++){var c=a[o];0!==r[c]&&(n=!1)}n&&(s.splice(e--,1),t=i(i.s=a[0]))}return t}var n={},r={app:0},s=[];function i(e){if(n[e])return n[e].exports;var a=n[e]={i:e,l:!1,exports:{}};return t[e].call(a.exports,a,a.exports,i),a.l=!0,a.exports}i.m=t,i.c=n,i.d=function(t,e,a){i.o(t,e)||Object.defineProperty(t,e,{enumerable:!0,get:a})},i.r=function(t){"undefined"!==typeof Symbol&&Symbol.toStringTag&&Object.defineProperty(t,Symbol.toStringTag,{value:"Module"}),Object.defineProperty(t,"__esModule",{value:!0})},i.t=function(t,e){if(1&e&&(t=i(t)),8&e)return t;if(4&e&&"object"===typeof t&&t&&t.__esModule)return t;var a=Object.create(null);if(i.r(a),Object.defineProperty(a,"default",{enumerable:!0,value:t}),2&e&&"string"!=typeof t)for(var n in t)i.d(a,n,function(e){return t[e]}.bind(null,n));return a},i.n=function(t){var e=t&&t.__esModule?function(){return t["default"]}:function(){return t};return i.d(e,"a",e),e},i.o=function(t,e){return Object.prototype.hasOwnProperty.call(t,e)},i.p="";var o=window["webpackJsonp"]=window["webpackJsonp"]||[],c=o.push.bind(o);o.push=e,o=o.slice();for(var d=0;d<o.length;d++)e(o[d]);var u=c;s.push([0,"chunk-vendors"]),a()})({0:function(t,e,a){t.exports=a("56d7")},"56d7":function(t,e,a){"use strict";a.r(e);a("e260"),a("e6cf"),a("cca6"),a("a79d");var n=a("2b0e"),r=a("43f9"),s=a.n(r),i=(a("51de"),a("e094"),function(){var t=this,e=t.$createElement,a=t._self._c||e;return a("transacoes")}),o=[],c=function(){var t=this,e=t.$createElement,a=t._self._c||e;return a("md-content",{staticStyle:{"max-width":"500px"}},[a("md-dialog",{attrs:{"md-active":t.abrir_diálogo_adicionar_transação},on:{"update:mdActive":function(e){t.abrir_diálogo_adicionar_transação=e},"update:md-active":function(e){t.abrir_diálogo_adicionar_transação=e}}},[a("md-dialog-title",[t._v(t._s(t.editando_transação?"Editar":"Adicionar")+" transação")]),a("md-datepicker",{model:{value:t.data,callback:function(e){t.data=e},expression:"data"}}),a("md-field",[a("label",[t._v("Descrição")]),a("md-input",{model:{value:t.descrição,callback:function(e){t.descrição=e},expression:"descrição"}})],1),a("md-field",[a("label",[t._v("Valor")]),a("span",{staticClass:"md-prefix"},[t._v("R$")]),a("md-input",{attrs:{type:"number",step:"0.01"},model:{value:t.valor,callback:function(e){t.valor=e},expression:"valor"}})],1),a("md-checkbox",{model:{value:t.repetir_mensalmente,callback:function(e){t.repetir_mensalmente=e},expression:"repetir_mensalmente"}},[t._v("Repetir mensalmente")]),a("md-dialog-actions",[a("md-button",{staticClass:"md-primary",on:{click:function(e){t.abrir_diálogo_adicionar_transação=!1}}},[t._v("Cancelar")]),a("md-button",{staticClass:"md-primary",on:{click:function(e){t.adicionar_transação()}}},[t._v("Ok")])],1)],1),a("md-toolbar",[a("md-menu",[a("md-button",{attrs:{"md-menu-trigger":""}},[t._v(t._s(t.mês))]),a("md-menu-content",t._l(t.possíveis_meses,(function(e,n){return a("md-menu-item",{key:n,on:{click:function(a){t.mês=e}}},[a("span",[t._v(t._s(e))])])})),1)],1),a("div",{staticClass:"md-toolbar-section-end"},[a("md-button",{staticClass:"md-icon-button",on:{click:function(e){t.editando_transação=!1,t.abrir_diálogo_adicionar_transação=!0}}},[a("md-icon",[t._v("add")])],1)],1)],1),t._l(t.dias,(function(e,n){return a("md-list",{key:n},[a("md-subheader",[t._v(t._s(e.id))]),t._l(e.transações.filter((function(e){return e.mês===t.mês})),(function(e,n){return a("md-list-item",{key:n},[a("md-checkbox",{staticStyle:{display:"none"}}),a("md-checkbox",{staticClass:"confirmar_transação",on:{change:function(a){t.atualizar_transação(e)}},model:{value:e.realizada,callback:function(a){t.$set(e,"realizada",a)},expression:"transação.realizada"}}),a("span",{staticClass:"md-list-item-text"},[t._v(t._s(e.descrição))]),a("span",{class:e.valor<0?"valor_negativo":""},[t._v(t._s(t.brl(e.valor)))]),a("md-menu",[a("md-button",{staticClass:"md-icon-button md-list-action",attrs:{"md-menu-trigger":""}},[a("md-icon",[t._v("more_vert")])],1),a("md-menu-content",[a("md-menu-item",{on:{click:function(a){t.editar_transação(e)}}},[a("md-icon",[t._v("edit")]),a("span",[t._v("Editar")])],1),a("md-menu-item",{on:{click:function(a){t.remover_transação(e)}}},[a("md-icon",[t._v("delete")]),a("span",[t._v("Remover")])],1)],1)],1)],1)}))],2)})),a("md-list",[a("md-subheader",[t._v("Saldo")]),a("md-list-item",[a("span",[t._v("Atual")]),a("span",{class:t.saldo_atual<0?"valor_negativo":""},[t._v(t._s(t.brl(t.saldo_atual)))])]),a("md-list-item",[a("span",[t._v("Inicial")]),a("span",{class:t.saldo_inicial<0?"valor_negativo":""},[t._v(t._s(t.brl(t.saldo_inicial)))])]),a("md-list-item",[a("span",[t._v("Final")]),a("span",{class:t.saldo_final<0?"valor_negativo":""},[t._v(t._s(t.brl(t.saldo_final)))])])],1),a("md-list",[a("md-subheader",[t._v("Alterações no mês")]),a("md-list-item",[a("span",[t._v("Receitas")]),a("span",{class:t.receitas<0?"valor_negativo":""},[t._v(t._s(t.brl(t.receitas)))])]),a("md-list-item",[a("span",[t._v("Despesas mensais")]),a("span",{class:t.despesas_mensais<0?"valor_negativo":""},[t._v(t._s(t.brl(t.despesas_mensais)))])]),a("md-list-item",[a("span",[t._v("Despesas esporádicas")]),a("span",{class:t.despesas_esporádicas<0?"valor_negativo":""},[t._v(t._s(t.brl(t.despesas_esporádicas)))])]),a("md-list-item",[a("span",[t._v("Variação do mês")]),a("span",{class:t.variação<0?"valor_negativo":""},[t._v(t._s(t.brl(t.variação)))])])],1)],2)},d=[],u=(a("4d90"),a("d3b7"),a("25f0"),a("7db0"),a("a434"),a("4e82"),a("a630"),a("3ca3"),a("6062"),a("ddb0"),a("d81d"),a("4de4"),a("1da1")),l=a("3835"),m=(a("96cf"),a("159b"),a("a15b"),a("e9c4"),indexedDB.open(location.pathname,1));m.onupgradeneeded=function(t){var e=t.target.result;e.createObjectStore("transações",{keyPath:"id",autoIncrement:!0})},m.onsuccess=function(t){var e=t.target.result;p=function(t){return t(e)},f.forEach(p)};var f=[],p=function(t){f.push(t)},_=[],v=[],h={adicionar:function(t,e){p((function(a){return a.transaction([t],"readwrite").objectStore(t).add(e).onsuccess=function(a){var n=a.target.result;e.id=n,_.forEach((function(a){var n=Object(l["a"])(a,2),r=n[0],s=n[1];t===r&&s(e)}))}}))},ao_adicionar:function(t,e){p((function(a){return a.transaction([t]).objectStore(t).openCursor().onsuccess=function(t){var a=t.target.result;a&&(e(a.value),a.continue())}})),_.push([t,e])},remover:function(t,e){p((function(a){return a.transaction([t],"readwrite").objectStore(t).delete(e).onsuccess=function(){v.forEach((function(a){var n=Object(l["a"])(a,2),r=n[0],s=n[1];t===r&&s(e)}))}}))},ao_remover:function(t,e){v.push([t,e])},atualizar:function(t,e){p((function(a){return a.transaction([t],"readwrite").objectStore(t).put(e)}))}};window.salvar=function(){var t=[];p((function(e){return e.transaction(["transações"]).objectStore("transações").openCursor().onsuccess=function(e){var a=e.target.result;a?(t.push(a.value),a.continue()):Object(u["a"])(regeneratorRuntime.mark((function e(){var a,n,r;return regeneratorRuntime.wrap((function(e){while(1)switch(e.prev=e.next){case 0:return a=new Date,e.next=3,window.showSaveFilePicker({suggestedName:[a.getFullYear(),(a.getMonth()+1).toString().padStart(2,0),a.getDate().toString().padStart(2,0),a.getHours(),a.getMinutes(),a.getSeconds()].join("-")+".json"});case 3:return n=e.sent,e.next=6,n.createWritable();case 6:return r=e.sent,e.next=9,r.write(new Blob([JSON.stringify(t)],{type:"application/json"}));case 9:return e.next=11,r.close();case 11:case"end":return e.stop()}}),e)})))()}}))};var b=new Date,g=b.getFullYear()+"-"+(b.getMonth()+1).toString().padStart(2,0),y=new Intl.NumberFormat("pt-BR",{style:"currency",currency:"BRL"}),S={data:function(){return{"mês":g,"abrir_diálogo_adicionar_transação":!1,"editando_transação":!1,data:b,"descrição":"",valor:0,repetir_mensalmente:!1,"transações":[],realizada:[]}},created:function(){var t=this;h.ao_adicionar("transações",(function(e){return t.transações.push(e)})),h.ao_remover("transações",(function(e){return t.transações.find((function(a,n){if(a.id===e)return t.transações.splice(n,1),!0}))}))},computed:{"possíveis_meses":function(){return Array.from(new Set(this.transações.map((function(t){return t.mês})))).sort()},dias:function(){var t=this;return this.transações.reduce((function(e,a){if(a.mês!==t.mês)return e;for(var n=a.data.getDate().toString().padStart(2,0)+" - "+["DOM","SEG","TER","QUA","QUI","SEX","SAB"][a.data.getDay()],r=0;r<e.length;r++){if(e[r].id>n)return e.splice(r,0,{id:n,"transações":[a]}),e;if(e[r].id===n)return e[r].transações.push(a),e}return e.push({id:n,"transações":[a]}),e}),[])},saldo_atual:function(){return this.transações.filter((function(t){return t.realizada})).map((function(t){return t.valor})).reduce((function(t,e){return t+e}),0)},saldo_inicial:function(){var t=this;return this.transações.filter((function(e){return e.mês<t.mês})).map((function(t){return t.valor})).reduce((function(t,e){return t+e}),0)},saldo_final:function(){return this.saldo_inicial+this.variação},receitas:function(){var t=this;return this.transações.filter((function(e){return e.mês===t.mês&&e.valor>0})).map((function(t){return t.valor})).reduce((function(t,e){return t+e}),0)},despesas_mensais:function(){var t=this;return this.transações.filter((function(e){return e.mês===t.mês&&e.valor<0&&e.repetir_mensalmente})).map((function(t){return t.valor})).reduce((function(t,e){return t+e}),0)},"despesas_esporádicas":function(){var t=this;return this.transações.filter((function(e){return e.mês===t.mês&&e.valor<0&&!e.repetir_mensalmente})).map((function(t){return t.valor})).reduce((function(t,e){return t+e}),0)},"variação":function(){return this.receitas+this.despesas_mensais+this.despesas_esporádicas}},methods:{"adicionar_transação":function(){this.editando_transação?(this.editando_transação.data=this.data,this.editando_transação.descrição=this.descrição,this.editando_transação.valor=parseFloat(this.valor),this.editando_transação.repetir_mensalmente=this.repetir_mensalmente,this.editando_transação.mês=this.data.getFullYear()+"-"+(this.data.getMonth()+1).toString().padStart(2,0),h.atualizar("transações",this.editando_transação)):h.adicionar("transações",{data:this.data,"descrição":this.descrição,valor:parseFloat(this.valor),repetir_mensalmente:this.repetir_mensalmente,realizada:null,repetida:!1,"mês":this.data.getFullYear()+"-"+(this.data.getMonth()+1).toString().padStart(2,0)}),this.data=b,this.descrição="",this.valor=0,this.repetir_mensalmente=!1,this.abrir_diálogo_adicionar_transação=!1},"editar_transação":function(t){this.editando_transação=t,this.data=new Date(t.data),this.descrição=t.descrição,this.valor=t.valor,this.repetir_mensalmente=t.repetir_mensalmente,this.abrir_diálogo_adicionar_transação=!0},"remover_transação":function(t){return h.remover("transações",t.id)},"atualizar_transação":function(t){t.repetir_mensalmente&&!t.repetida&&(this.data=new Date(t.data),this.data.setMonth(this.data.getMonth()+1),this.descrição=t.descrição,this.valor=t.valor,this.repetir_mensalmente=!0,this.adicionar_transação(),t.repetida=!0),h.atualizar("transações",t)},brl:function(t){return y.format(t)}}},w=S,x=(a("d02e"),a("2877")),k=Object(x["a"])(w,c,d,!1,null,null,null),j=k.exports,O={components:{Transacoes:j}},D=O,M=Object(x["a"])(D,i,o,!1,null,null,null),z=M.exports;n["default"].use(s.a),n["default"].config.productionTip=!1,new n["default"]({render:function(t){return t(z)}}).$mount("#app")},d02e:function(t,e,a){"use strict";a("f001")},f001:function(t,e,a){}});
//# sourceMappingURL=app.c025522a.js.map