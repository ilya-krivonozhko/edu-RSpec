# Шпаргалка по RSpec

## [Официальная документация](https://rspec.info/documentation/)

## [Соглашения по стилю кода](https://rspec.rubystyle.guide/)

## Содержание

1. [Объявление тестов и группировка примеров](#объявление-тестов-и-группировка-примеров)
2. [Методы ожиданий и матчеры](#методы-ожиданий-и-матчеры)
3. [Объявление тестовых объектов (`let`)](#объявление-тестовых-объектов-let)
4. [Использование `described_class`](#использование-described_class)
5. [Использование `double` и изоляция](#использование-double-и-изоляция)
6. [Хуки: `before`, `after`, `around`](#хуки-before-after-around)
7. [Теги и метаданные](#теги-и-метаданные)
8. [Запуск RSpec из командной строки](#запуск-rspec-из-командной-строки)

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
## Объявление тестовых объектов (`let`)
* `let` - ленивый (вычисляется при первом обращении)
* `let!` - жадный (вычисляется перед каждым примером)
```ruby
RSpec.describe 'Using let' do
  let(:user) { { name: 'Alice', age: 30 } }  # мемоизированный хелпер

  it 'can access the memoized user' do
    expect(user[:name]).to eq('Alice')
  end
end
```
* `let` мемоизируется на уровень примера и не разделяется между примерами
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
## Использование `double` и изоляция
### Фиктивный класс для тестирования модулей (не является RSpec double)
Модули нельзя инстанцировать — тестируйте их через фиктивный класс. Этот подход полезен при тестировании модулей, имеющих поведение, но не имеющих состояния.
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
### Stub vs Mock vs Spy vs Null Object
![img](img/img.png)

RSpec предоставляет несколько типов тестовых двойников (test doubles), каждый из которых предназначен для своей задачи.
#### Stub
Stub задаёт заранее определённый ответ, но сам по себе не устанавливает ожиданий.
```ruby
converter = double(:converter, convert: 100)
converter.convert # => 100
```
#### Mock
Mock устанавливает ожидания до выполнения и проваливает тест, если они не были выполнены.
```ruby
converter = double(:converter)
expect(converter).to receive(:convert)
converter.convert
```
#### Spy
Spy записывает вызовы методов и позволяет проверять ожидания после выполнения.
```ruby
converter = spy(:converter)
converter.convert
expect(converter).to have_received(:convert)
```
В современном RSpec spy обычно предпочтительнее классических моков, так как позволяют проверять взаимодействия после выполнения, не связывая тест с порядком вызовов.
#### Null Object
Null Object отвечает на любое сообщение, не выбрасывая ошибок.
```ruby
converter = double(:converter).as_null_object
converter.anything
```
#### Verifying doubles
Verifying doubles гарантируют, что заглушенные или ожидаемые методы существуют в реальном объекте. Они дают более строгие гарантии за счёт:
* проверки существования метода
* проверки видимости метода
* падения тестов при изменении реального интерфейса
```ruby
converter = instance_double(Converter)
```
По сравнению с обычными double, verifying doubles помогают поддерживать тесты в соответствии с реальным кодом.
```ruby
double(:converter)          # без проверки интерфейса
instance_double(Converter)  # проверяет методы экземпляра(#method)
class_double(Converter)     # проверяет методы класса(.method)
```
#### Эквивалентность сокращённого синтаксиса stub
Следующие два варианта эквивалентны.
```ruby
converter = instance_double(described_class, convert: 100)
```
Эквивалентно:
```ruby
converter = instance_double(described_class)
allow(converter).to receive(:convert).and_return(100)
```
Сокращённая форма — это синтаксический сахар, удобный для простых случаев. Используйте явный `allow`, если требуется более сложная настройка.
#### Ограничение аргументов с помощью `with`
Можно ограничить заглушки или ожидания так, чтобы они срабатывали только для определённых аргументов.
```ruby
allow(converter).to receive(:convert)
  .with(sum: 80)
  .and_return(100)
```
Если метод будет вызван с другими аргументами, тест упадёт. Это делает ожидания более точными.
#### Частичные двойники (partial doubles / partial stubs)
Partial double — это реальный объект, у которого подменены некоторые методы. Используйте partial doubles с осторожностью, так как они жёстко связывают тесты с деталями реализации.
```ruby
specify '#transfer_with_conversion' do
  allow(john).to receive(:convert)
    .with(sum: 50, from: :usd, to: :eur)
    .and_return(40)

  john.transfer_with_conversion(ann, 50, :usd, :eur)

  expect(john.balance).to eq(50)
  expect(ann.balance).to eq(40)
  expect(john).to have_received(:convert).once
end
```
Partial doubles полезны, когда нужно тестировать реальное поведение, изолируя конкретные зависимости.
### Matchers для spies
Spies позволяют проверять полученные сообщения после выполнения.
```ruby
user = spy(:user)
user.login
user.logout
expect(user).to have_received(:login)
expect(user).to have_received(:logout).once
expect(user).to have_received(:login).with(no_args)
```
Распространённые matchers для spies:
* `have_received`
* `once`, `twice`
* `exactly(n).times`
* `with(...)`
* `ordered`
#### Настройка ответов (RSpec Mocks)
При разрешении `allow` или ожидании `expect` сообщений, ответ по умолчанию — `nil`. RSpec предоставляет несколько способов настроить поведение.
##### `and_return` - возвращает конкретное значение.
```ruby
allow(converter).to receive(:convert).and_return(100)
```
##### `and_raise` - выбрасывает исключение.
```ruby
allow(converter).to receive(:convert).and_raise(StandardError)
```
##### `and_throw` - выполняет `throw` символа.
```ruby
allow(converter).to receive(:convert).and_throw(:error)
```
##### `and_yield` - передаёт управление в блок.
```ruby
allow(converter).to receive(:convert).and_yield(100)
```
##### `and_call_original` - вызывает оригинальную реализацию метода.
```ruby
allow(converter).to receive(:convert).and_call_original
```
##### `and_wrap_original` - оборачивает оригинальный метод.
```ruby
allow(converter).to receive(:convert).and_wrap_original do |original, *args|
  original.call(*args) * 2
end
```
##### `and_invoke` - вызывает переданный вызываемый объект.
```ruby
allow(converter).to receive(:convert).and_invoke(-> { 100 })
```
## Хуки: `before`, `after`, `around`
Предпочитайте `let` вместо переменных экземпляра `@var`, хотя переменные экземпляра по-прежнему поддерживаются
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
### Теги на уровне `describe` / `context`
```ruby
RSpec.describe 'Utils', :utils do
  it 'inherits metadata from describe' do
    expect(true).to eq(true)
  end
end
```
### Метаданные на основе директорий (`spec_helper.rb`)
Назначение метаданных всем спецификациям в директории:
```ruby
RSpec.configure do |config|
  config.define_derived_metadata(file_path: %r{exchange_it/utils}) do |meta|
    meta[:utils] = true
  end
end
```
### Платформо-зависимые тесты (`spec_helper.rb`)
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
### Запуск только неудачных спецификаций из предыдущего прогона
В `spec_helper.rb` нужно добавить:
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
или
```bash
rspec --order rand
```
### Цветной вывод
```bash
rspec --color
```
