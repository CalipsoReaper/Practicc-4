#!/bin/bash
# Функция для вывода справки
show_help() {
    echo "Использование: $0 [опции]"
    echo
    echo "Опции:"
    echo "  -u, --users       Вывести перечень пользователей и их домашних директорий"
    echo "  -p, --processes   Вывести перечень запущенных процессов"
    echo "  -h, --help        Вывести справку"
    echo "  -l PATH, --log PATH   Перенаправить вывод в файл по заданному пути"
    echo "  -e PATH, --errors PATH Перенаправить вывод ошибок в файл по заданному пути"
} 

# Функция для вывода пользователей и их домашних директорий
list_users() {
    if [[ $EUID -ne 0 ]]; then
        echo "Ошибка: Для просмотра пользователей требуется права суперпользователя." >&2
        exit 1
    fi

    if [[ -n "$log_file" ]]; then
        exec > "$log_file"
    fi

    while IFS=: read -r username home_dir; do
        if [[ -n "$username" && -n "$home_dir" ]]; then
            echo "$username $home_dir"
        fi
    done < /etc/passwd | sort
}

# Функция для вывода запущенных процессов 1
list_processes() {
    if [[ -n "$log_file" ]]; then
        exec > "$log_file"
    fi

    ps -e --format pid,cmd --sort pid
}

# Основа
log_file=""
error_file=""

while getopts ":uphl:e:-:" opt; do
    case $opt in
        u)
            list_users
            exit 0
            ;;
        p)
            list_processes
            exit 0
            ;;
        h)
            show_help
            exit 0
            ;;
        l)
            log_file="$OPTARG"
            ;;
        e)
            error_file="$OPTARG"
            ;;
        -)
            case "${OPTARG}" in
                users)
                    list_users
                    exit 0
                    ;;
                processes)
                    list_processes
                    exit 0
                    ;;
                help)
                    show_help
                    exit 0
                    ;;
                log)
                    log_file="${!OPTIND}"; OPTIND=$((OPTIND + 1))
                    ;;
                errors)
                    error_file="${!OPTIND}"; OPTIND=$((OPTIND + 1))
                    ;;
                *)
                    echo "Неверный аргумент: --${OPTARG}" >&2
                    show_help >&2
                    exit 1
                    ;;
            esac
            ;;
        \?)
            echo "Неверный аргумент: -$OPTARG" >&2
            show_help >&2
            exit 1
            ;;
        :)
            echo "Аргумент для -$OPTARG отсутствует." >&2
            show_help >&2
            exit 1
            ;;
    esac
done

# Обработка перенаправления ошибок, если указано
if [[ -n "$error_file" ]]; then
    exec 2> "$error_file"
fi

trap "echo 'ой-ой ошибка'>&2" DEBUG
# Если не переданы аргументы, выводим справку
if [[ -z "$log_file" && -z "$error_file" ]]; then
    show_help
fi

