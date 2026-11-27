// Package clock lets code ask for the time through a port, so tests can fix it.
package clock

import "time"

// Clock tells the current time.
type Clock interface {
	Now() time.Time
}

// System is the real clock.
type System struct{}

// Now returns the current time.
func (System) Now() time.Time { return time.Now() }
