import{_ as c,q as n,l as u,m as d,A as o,K as a,v as s,u as p,x as l}from"./vendor-b78ff8c0.js";import"./vendor-sortablejs-116030fd.js";const _={name:"DeviceJanitzaCounter",emits:["update:configuration"],props:{configuration:{type:Object,required:!0},deviceId:{default:void 0},componentId:{required:!0}},methods:{updateConfiguration(e,t=void 0){this.$emit("update:configuration",{value:e,object:t})}}},f={class:"device-janitza-counter"},m={class:"small"};function b(e,t,v,g,h,w){const i=n("openwb-base-heading"),r=n("openwb-base-alert");return u(),d("div",f,[o(i,null,{default:a(()=>[s(" Einstellungen für Janitza Zähler "),p("span",m,"(Modul: "+l(e.$options.name)+")",1)]),_:1}),o(r,{subtype:"info"},{default:a(()=>[s(' ModbusTCP muss im Janitza auf Port 502 aktiv und die ID auf "1" eingestellt sein. ')]),_:1})])}const z=c(_,[["render",b],["__file","/opt/openWB-dev/openwb-ui-settings/src/components/devices/janitza/counter.vue"]]);export{z as default};