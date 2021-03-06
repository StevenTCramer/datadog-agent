// Unless explicitly stated otherwise all files in this repository are licensed
// under the Apache License Version 2.0.
// This product includes software developed at Datadog (https://www.datadoghq.com/).
// Copyright 2016-2019 Datadog, Inc.

package config

import (
	"io"
	"strings"
	"time"

	"github.com/spf13/afero"
	"github.com/spf13/pflag"
)

// Config represents an object that can load and store configuration parameters
// coming from different kind of sources:
// - defaults
// - files
// - environment variables
// - flags
type Config interface {

	// API implemented by viper.Viper

	Set(key string, value interface{})
	SetDefault(key string, value interface{})
	SetFs(fs afero.Fs)
	IsSet(key string) bool

	Get(key string) interface{}
	GetString(key string) string
	GetBool(key string) bool
	GetInt(key string) int
	GetInt64(key string) int64
	GetFloat64(key string) float64
	GetTime(key string) time.Time
	GetDuration(key string) time.Duration
	GetStringSlice(key string) []string
	GetStringMap(key string) map[string]interface{}
	GetStringMapString(key string) map[string]string
	GetStringMapStringSlice(key string) map[string][]string
	GetSizeInBytes(key string) uint

	SetEnvPrefix(in string)
	BindEnv(input ...string) error
	SetEnvKeyReplacer(r *strings.Replacer)

	UnmarshalKey(key string, rawVal interface{}) error
	Unmarshal(rawVal interface{}) error
	UnmarshalExact(rawVal interface{}) error

	ReadInConfig() error
	ReadConfig(in io.Reader) error
	MergeConfig(in io.Reader) error

	AllSettings() map[string]interface{}

	AddConfigPath(in string)
	SetConfigName(in string)
	SetConfigFile(in string)
	SetConfigType(in string)
	ConfigFileUsed() string

	BindPFlag(key string, flag *pflag.Flag) error

	// API not implemented by viper.Viper and that have proven useful for our config usage

	// BindEnvAndSetDefault sets the default value for a config parameter and adds an env binding
	// in one call, used for most config options
	BindEnvAndSetDefault(key string, val interface{})
	// GetEnvVars returns a list of the non-sensitive env vars that the config supports
	GetEnvVars() []string
}
