---
date: '2024-11-19'
draft: false
title: '[PL Golang] Go-常见设计模式'
description: 'Go语言中常见的设计模式'
tags: ["golang"]
categories: ["golang"]
---
# Go常用的设计模式

Go项目开发中比较常用的设计模式

- 创建型模式
  - 单例模式
  - 工厂模式
- 结构型模式
  - 策略模式
  - 模板模式
- 行为型模式
  - 代理模式
  - 选项模式

## 创建型模式

### 单例模式
```go
package singleton

import "sync"

type singleton struct {}

var ins *singleton
var once sync.Once

func GetInsOr() *singleton{
    once.Do(func(){
        ins = &singleton{}
    })
    return nil
}
```
使用`once.Do`可以确保ins实例全局被创建一次

单例模式实际上有饿汉方式和懒汉方式，这里只介绍在Go项目中单例模式最优雅的实现方式

### 工厂模式
工厂模式是**面向对象编程中的常用模式**。可以通过不同的工厂模式来带得Go项目变得简洁

- 简单工厂模式

```go
package factory

type Person struct{
    Name string
    Age  string
}

func (p Person) Greet() {
    fmt.Printf("name := %s, age := %s", p.Name, p.Age)
}

func NewPerson(name string, age int) *Person {
    return &Person{
        Name: name,
        Age: age,
    }
}
```
通过`NewPerson`创建实例，可以确保实例的Name和Age属性被设置

- 抽象工厂模式

抽象工厂模式和简单工厂模式的唯一区别，返回的是**接口**而不是结构体

通过返回接口，可以在不公开内部实现的情况下，让调用者使用提供的各种功能

```go
package factory

type PersonIntf interface {
  Greet()
}

type person struct {
  name string
  age int
}

func (p person) Greet() {
  fmt.Printf("Hi! My name is %s", p.name)
}

// Here, NewPerson returns an interface, and not the person struct itself
func NewPerson(name string, age int) PersonIntf {
  return person{
    name: name,
    age: age,
  }
}
```

- 工厂方式模式

在工厂方法模式，依赖工厂函数，通过实现工厂函数来创建多种工厂，将对象创建从由一个对象辅助所有具体类的实例化，变成由一群子类来负责具体类的实例化

```go
package factory

type Person struct {
	name string
	age int
}

func NewPersonFactory(age int) func(name string) Person {
	return func(name string) Person {
		return Person{
			name: name,
			age: age,
		}
	}
}
```

## 结构型模式

结构型模式特点：**关注类和对象的组合**

### 策略模式

策略模式定义一个组算法，将每个算法都封装起来，并且使它们之间可以切换，根据不同的场景，采用不同的措施，即是不同的策略。

通过策略模式，定义一些独立的类来封装不同的算法，每个类封装一个具体的算法（策略）

```go
package strategy

type IStrategy interface {
    do(int, int) int
}

// 策略实现：加
type add struct{}

func (*add) do(a, b int) int {
	return a + b
}

// 策略实现：减
type reduce struct{}

func (*reduce) do(a, b int) int {
	return a - b
}

// 具体策略的执行者
type Operator struct {
	strategy IStrategy
}

// 设置策略
func (operator *Operator) setStrategy(strategy IStrategy) {
	operator.strategy = strategy
}

// 调用策略中的方法
func (operator *Operator) calculate(a, b int) int {
	return operator.strategy.do(a, b)
}
```

### 模板模式

模板模式定义一个操作中算法的骨架，而将一些步骤延迟到子类中

```go
package template

import "fmt"

type Cooker interface {
	fire()
	cooke()
	outfire()
}

// 类似于一个抽象类
type CookMenu struct {
}

func (CookMenu) fire() {
	fmt.Println("开火")
}

// 做菜，交给具体的子类实现
func (CookMenu) cooke() {
}

func (CookMenu) outfire() {
	fmt.Println("关火")
}

// 封装具体步骤
func doCook(cook Cooker) {
	cook.fire()
	cook.cooke()
	cook.outfire()
}

type XiHongShi struct {
	CookMenu
}

func (*XiHongShi) cooke() {
	fmt.Println("做西红柿")
}

type ChaoJiDan struct {
	CookMenu
}

func (ChaoJiDan) cooke() {
	fmt.Println("做炒鸡蛋")
}
```

## 行为型模式

行为型模式，特点是**关注对象之间的通信**

### 代理模式

代理模式为另一个对象提供一个替身或者占位符号，以控制对像的访问

```go
package proxy

import "fmt"

type Seller interface {
	sell(name string)
}

// 火车站
type Station struct {
	stock int //库存
}

func (station *Station) sell(name string) {
	if station.stock > 0 {
		station.stock--
		fmt.Printf("代理点中：%s买了一张票,剩余：%d \n", name, station.stock)
	} else {
		fmt.Println("票已售空")
	}

}

// 火车代理点
type StationProxy struct {
	station *Station // 持有一个火车站对象
}

func (proxy *StationProxy) sell(name string) {
	if proxy.station.stock > 0 {
		proxy.station.stock--
		fmt.Printf("代理点中：%s买了一张票,剩余：%d \n", name, proxy.station.stock)
	} else {
		fmt.Println("票已售空")
	}
}
```

StationProxy代理了Station

### 选项模式

选择模式是Go项目开发中经常使用到的模式。使用选项模式，可以创建一个带有默认值的struct变量，并选择地修改其中某一些参数的值

```go
package options

import (
	"time"
)

type Connection struct {
	addr    string
	cache   bool
	timeout time.Duration
}

const (
	defaultTimeout = 10
	defaultCaching = false
)

type options struct {
	timeout time.Duration
	caching bool
}

// Option overrides behavior of Connect.
type Option interface {
	apply(*options)
}

type optionFunc func(*options)

func (f optionFunc) apply(o *options) {
	f(o)
}

func WithTimeout(t time.Duration) Option {
	return optionFunc(func(o *options) {
		o.timeout = t
	})
}

func WithCaching(cache bool) Option {
	return optionFunc(func(o *options) {
		o.caching = cache
	})
}

// Connect creates a connection.
func NewConnect(addr string, opts ...Option) (*Connection, error) {
	options := options{
		timeout: defaultTimeout,
		caching: defaultCaching,
	}

	for _, o := range opts {
		o.apply(&options)
	}

	return &Connection{
		addr:    addr,
		cache:   options.caching,
		timeout: options.timeout,
	}, nil
}
```

选项模式通常适用于以下场景：

- 结构体参数很多，创建结构体时，我们期望创建一个携带默认值的结构体变量，并选择性修改其中一些参数的值。
- 结构体参数经常变动，变动时我们又不想修改创建实例的函数。例如：结构体新增一个retry参数，但是又不想在NewConnect入参列表中添加retry int这样的参数声明。