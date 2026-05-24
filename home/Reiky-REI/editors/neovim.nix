_: {
  programs.vim = {
    enable = true;
    extraConfig = ''
      set expandtab
      set tabstop=2
      set shiftwidth=2
      set softtabstop=2
      set number
      set relativenumber
      set mouse=a
      set clipboard=unnamedplus
      set cursorline
      set cursorcolumn
      set hidden
      set nohlsearch
      set incsearch
      set ignorecase
      set smartcase
      set nowrap
      set noswapfile
      set nobackup
      set undofile
      set scrolloff=8
      set splitright
      set splitbelow
      set signcolumn=yes

      nnoremap <C-h> <C-w><C-h>
      nnoremap <C-l> <C-w><C-l>
      nnoremap <C-j> <C-w><C-j>
      nnoremap <C-k> <C-w><C-k>
      tnoremap <Esc> <C-\><C-n>
      tnoremap <C-h> <C-\><C-n><C-w>h
      tnoremap <C-l> <C-\><C-n><C-w>l
      tnoremap <C-j> <C-\><C-n><C-w>j
      tnoremap <C-k> <C-\><C-n><C-w>k
      vnoremap <Leader>y "+y
      nmap <Leader>y "+y
      nmap <Leader>p "+p
      nmap <Leader>P "+P
      vnoremap <Leader>p "+p
      vnoremap <Leader>P "+P
      cnoremap <C-p> <Up>
      cnoremap <C-n> <Down>
    '';
  };
}
