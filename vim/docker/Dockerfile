FROM ubuntu:22.04

RUN apt-get update
RUN apt-get install -y git language-pack-en curl libfuse2 host xz-utils fontconfig make npm
RUN update-locale

RUN git clone https://github.com/Feelinglight/tools_tuning "/root/tools_tuning"

# zsh
WORKDIR "/root/tools_tuning/linux/zsh"
COPY ./key-bindings.zsh /usr/share/doc/fzf/examples/key-bindings.zsh
RUN sed -i 's/\bsudo \b//g' setup.sh
RUN ./setup.sh
# RUN chsh -s $(which zsh)

# nvim
RUN curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
RUN chmod +x nvim.appimage
RUN mv nvim.appimage /usr/local/bin/nvim


RUN rm -rf "/root/tools_tuning"

# Для серого шрифта в zsh-autosuggestions
ENV TERM xterm-256color

WORKDIR "/root/.config/nvim/lua"

ADD cmd.sh /usr/local/bin/cmd.sh
# CMD /usr/local/bin/cmd.sh
CMD /bin/zsh
