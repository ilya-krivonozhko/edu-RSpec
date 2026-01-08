# Шпаргалка по RSpec

## Содержание

1. [Объявление тестов и группировка примеров](#объявление-тестов-и-группировка-примеров)
2. [Методы ожиданий и матчеры](#методы-ожиданий-и-матчеры)
3. [Объявление тестовых объектов (let)](#объявление-тестовых-объектов-let)
4. [Использование described_class](#использование-described_class)
5. [Использование стабов и даблов](#использование-стабов-и-даблов)
6. [Фиктивный класс для тестирования модулей](#фиктивный-класс-для-тестирования-модулей)
7. [Хуки: before, after, around](#хуки-before-after-around)
8. [Теги и метаданные](#теги-и-метаданные)
9. [Запуск RSpec из командной строки](#запуск-rspec-из-командной-строки)

## Объявление тестов и группировка примеров

```ruby
RSpec.describe 'Array' do
  # it: самый распространённый способ объявления примера
  it 'has size 0 when newly created' do
    expect(Array.new.size).to eq(0)
  end

  # specify: алиас для it
  specify 'new array is empty' do
    expect(Array.new).to be_empty
  end

  # example: алиас для it
  example 'new array has length 0' do
    expect(Array.new.length).to eq(0)
  end

  # describe: группирует связанные примеры
  # describe — ЧТО тестируется (класс, метод)
  describe '#push' do
    it 'adds an element to the array' do
      arr = []
      arr.push(1)
      expect(arr).to eq([1])
    end
  end

  # context: алиас для describe, используется для повышения читаемости
  # context — КОГДА / при каких условиях
  context 'when the array is empty' do
    it 'has size zero' do
      expect(Array.new.size).to eq(0)
    end
  end
end
```
## Методы ожиданий и матчеры
```ruby
RSpec.describe 'Matchers' do
  it 'supports basic matchers' do
    expect(5).to eq(5)                # проверка на равенство
    expect(nil).to be_nil             # проверка на nil
    expect([1,2,3]).to include(2)     # проверка на наличие элемента
    expect(10).not_to eq(5)           # отрицательное ожидание
    # строже, чем be_a / be_an / be_kind_of (не допускает подклассы)
    expect("Hello").to be_an_instance_of(String) # проверка типа
    end
end
```
## Объявление тестовых объектов (let)
* let - ленивый (вычисляется при первом обращении)
* let! - жадный (вычисляется перед каждым примером)
```ruby
RSpec.describe 'Using let' do
  let(:user) { { name: 'Alice', age: 30 } }  # мемоизированный хелпер

  it 'can access the memoized user' do
    expect(user[:name]).to eq('Alice')
  end
end
```
* let мемоизируется на уровень примера и не разделяется между примерами
## Использование described_class
```ruby
RSpec.describe ExchangeIt::Account do
  let(:user_class) { Struct.new(:name, :surname) }
  let(:john) { described_class.new(user_class.new('John', 'Doe')) }

  it 'initializes with user' do
    expect(john).to be_a(described_class)
  end
end
```
## Использование стабов и даблов
```ruby
class Service
  def perform; end
end

RSpec.describe Service do
  it 'can be stubbed' do
    fake_service = double('Service')
    allow(fake_service).to receive(:perform).and_return(true)
    expect(fake_service.perform).to eq(true)
  end
end
```
Предпочитайте проверяемые даблы, когда это возможно:
* instance_double(Service) — проверяет интерфейс экземпляра
* class_double(Service) — проверяет интерфейс класса
```ruby
fake_service = instance_double(Service, perform: true)
expect(fake_service.perform).to eq(true)
```
## Фиктивный класс для тестирования модулей
Модули нельзя инстанцировать — тестируйте их через фиктивный класс.
```ruby
module ExchangeIt
  module Utils
    module Uid
      def generate; 'uid' end
    end
  end
end

RSpec.describe ExchangeIt::Utils::Uid do
  let(:dummy) { Class.new { include ExchangeIt::Utils::Uid }.new }

  it 'can call methods from the included module' do
    expect(dummy.generate).to eq('uid')
  end
end
```
## Хуки: before, after, around
Предпочитайте `let` вместо переменных экземпляра (`@var`), хотя переменные экземпляра по-прежнему поддерживаются
```ruby
RSpec.describe 'Hooks' do
  before(:each) do
    @arr = []
  end

  after(:each) do
    @arr.clear
  end

  around(:each) do |example|
    puts "Before example"
    example.run
    puts "After example"
  end

  it 'uses before hook' do
    @arr.push(1)
    expect(@arr).to eq([1])
  end
end
```
## Теги и метаданные
Теги обычно используются для:
* запуска медленных / быстрых спецификаций
* разделения интеграционных тестов
* включения платформо-зависимого поведения
### Tags on examples
```ruby
RSpec.describe 'Tags' do
  # Эти две формы эквивалентны:
  # it 'has zero balance', fast: true do
  # it 'has zero balance', :fast do
  #
  # Предпочтительна форма с символом (:fast).

  it 'has zero balance', :fast do
    expect(0).to eq(0)
  end
end
```
### Теги на уровне describe / context
```ruby
RSpec.describe 'Utils', :utils do
  it 'inherits metadata from describe' do
    expect(true).to eq(true)
  end
end
```
### Метаданные на основе директорий (spec_helper.rb)
Назначение метаданных всем спецификациям в директории:
```ruby
RSpec.configure do |config|
  config.define_derived_metadata(file_path: %r{exchange_it/utils}) do |meta|
    meta[:utils] = true
  end
end
```
### Платформо-зависимые тесты (spec_helper.rb)
Пример: исключить спецификации, если тесты запускаются не на Linux
```ruby
RSpec.configure do |config|
  config.filter_run_excluding :linux_only unless RUBY_PLATFORM.include?('x86_64-linux')
end
```
## Запуск RSpec из командной строки
### Запуск только спецификаций с определённым тегом
```bash
rspec --tag fast
```
### Исключение спецификаций с определённым тегом
```bash
rspec --tag ~fast
```
### Запуск спецификаций по описанию (поиск по имени)
```bash
rspec -e name
```
### Запуск только упавших спецификаций из предыдущего прогона
В spec_helper.rb нужно добавить:
```ruby
RSpec.configure do |config|
  config.example_status_persistence_file_path = 'spec/specs.txt'
end
```
Затем запустить:
```bash
rspec . --only-failures
```
### Поиск самых медленных спецификаций
```bash
rspec . --profile 3
```
(число 3 можно заменить на любое другое)
### Фокусированные тесты
RSpec предоставляет «фокусированные» версии примеров и групп:
* `fit` → то же самое, что `it ..., :focus`
* `fspecify` → то же самое, что `specify ..., :focus`
* `fdescribe` → то же самое, что `describe ..., :focus`
Запуск фокусированных тестов:
```bash
rspec --tag focus .
```
### Формат документации
```bash
rspec --format documentation
```
### Воспроизведение ошибок, зависящих от случайного порядка тестирования
```bash
rspec --seed 12345
```
or
```bash
rspec --order rand
```
### Цветной вывод
```bash
rspec --color
```
