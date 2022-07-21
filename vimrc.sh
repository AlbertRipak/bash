#!/bin/bash

cd
touch .vimrc

echo '
" ~/.vimrc

" Отступы и нумерация строк
" переменная expandtab - заменяет табы на пробелы
set expandtab

" smarttab - при нажатии таба в начале строки доавляет количество пробелов
" равное shiftwidth
set smarttab

" tabstop - количество пробелов в одном обычном tab
set tabstop=4

" softtabtstop - количество пробелов в табе при удfлении
set softtabstop=4

" shiftwidth - количество пробелов
set shiftwidth=4

" number - нумерация срок
set number

" foldcolumn - отступы между левой частью окна
set foldcolumn=2

" colorscheme - цветовая схема
colorscheme darkblue

" syntax on - включает подсветку синтаксиса
syntax on

" отключаем звук при нажатии не той кнопки
set noerrorbells
set novisualbell

" set mouse=a - поддержка миши в граф. интерф.
set mouse=a

" Смотрим поддерживает ли vim работу с системным буфером обмена
" vim --version | grep clipboard
" Если есть +clipboard всё хорошо

" Настройка поиска 
" игнорируем регистр
set ignorecase
set smartcase

" подсвечивать результат поиска 
set hlsearch

" что бы програма подсказала первое вхождиние поиска
set incsearch

" кодировка
set encoding=utf8
' > ./.vimrc