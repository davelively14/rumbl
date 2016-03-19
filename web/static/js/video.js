import Player from "./player"

let Video = {

  init(socket, element){ if(!element){ return }
    let playerId = element.getAttribute("data-player-id")
    let videoId  = element.getAttribute("data-id")
    socket.connect()
    Player.init(element.id, playerId, () => {

      // Runs after Player has loaded
      this.onReady(videoId, socket)
    })
  },

  // DOM element variables for our Video player:
  // msgContainer is for annotations
  // msgInput, postButton are both for creating a new annotation
  // vidChannel will connects our ES6 client to the Phoenix VideoChannel
  // The topics, which in this case are the videos, will need an identifier. We
  // take the form (conventionally) videos: + videoId. This lets us send events
  // easily to others interested in the same topic
  onReady(videoId, socket){
    let msgContainer = document.getElementById("msg-container")
    let msgInput     = document.getElementById("msg-input")
    let postButton   = document.getElementById("msg-submit")

    let vidChannel   = socket.channel("videos:" + videoId)

    // When user clicks the msg-submit element, we take the content of the
    // msg-input, send it to the server, then clear the msg-input control.
    postButton.addEventListener("click", e => {
      let payload = {body: msgInput.value, at: Player.getCurrentTime()}

      // This is the channels synchronous messaging. It's not truly synchronous,
      // but it does make readability easier. For every push of an event to the
      // server, we can optionally receive a response. Allows for request/
      // response style messaging over a socket connection.
      vidChannel.push("new_annotation", payload)
                .receive("error", e => console.log(e))
      msgInput.value = ""
    })

    // Handles new events sent by the server and renders in the msg-container
    vidChannel.on("new_annotation", (resp) => {
      this.renderAnnotation(msgContainer, resp)
    })

    vidChannel.join()
      .receive("ok", ({annotations}) => {
        annotations.forEach( ann => this.renderAnnotation(msgContainer, ann) )
      })
      .receive("error", reason => console.log("join failed", reason))
    vidChannel.on("ping", ({count}) => console.log("PING", count))
  },

  // Something in here protects against cross-site scripting attacks? This
  // escapes user input. Will only return the string inside. I think I get it.
  esc(str){
    let div = document.createElement("div")
    div.appendChild(document.createTextNode(str))
    return div.innerHTML
  },

  renderAnnotation(msgContainer, {user, body, at}){
    let template = document.createElement("div")
    template.innerHTML = `
    <a href="#" data-seek="${this.esc(at)}">
      <b>${this.esc(user.username)}</b>: ${this.esc(body)}
    </a>
    `
    msgContainer.appendChild(template)
    msgContainer.scrollTop = msgContainer.scrollHeight
  }
}
export default Video
